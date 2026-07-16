import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final reminderService = ReminderService();

class ReminderService {
  final _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        windows: WindowsInitializationSettings(
          appName: 'Lumen Biblia',
          appUserModelId: 'LumenBiblia.Reader',
          guid: '4eb0f179-9c83-4e7b-bfe7-836db42f5740',
        ),
      ),
    );
    _initialized = true;
  }

  Future<void> scheduleDaily(int hour, int minute) async {
    await initialize();
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    var next = tz.TZDateTime(
      tz.local,
      tz.TZDateTime.now(tz.local).year,
      tz.TZDateTime.now(tz.local).month,
      tz.TZDateTime.now(tz.local).day,
      hour,
      minute,
    );
    if (!next.isAfter(tz.TZDateTime.now(tz.local))) {
      next = next.add(const Duration(days: 1));
    }
    await _notifications.cancel(id: 100);
    await _notifications.zonedSchedule(
      id: 100,
      title: 'Tu momento de lectura',
      body: 'Continúa hoy tu camino en Lumen Biblia.',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_reminders',
          'Recordatorios de lectura',
          channelDescription: 'Recordatorio diario para continuar la lectura',
        ),
        iOS: DarwinNotificationDetails(),
        windows: WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // ponytail: Windows solo agenda la próxima aparición; reprogramar al
      // abrir la app hasta que el plugin admita recurrencia diaria en Windows.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    await initialize();
    await _notifications.cancel(id: 100);
  }
}
