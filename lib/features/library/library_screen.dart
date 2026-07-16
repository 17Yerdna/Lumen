part of '../../screens.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String section = 'notes';

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final favorites = ref.watch(favoritesProvider);
    return PageFrame(
      maxWidth: 960,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeading(
            title: 'Notas y guardados',
            subtitle: 'Tus reflexiones permanecen privadas.',
            trailing: FilledButton.icon(
              onPressed: () => context.go('/reader'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nueva nota'),
            ),
          ),
          const SizedBox(height: 24),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'notes',
                label: Text('Notas'),
                icon: Icon(Icons.edit_note_rounded),
              ),
              ButtonSegment(
                value: 'favorites',
                label: Text('Favoritos'),
                icon: Icon(Icons.bookmark_outline_rounded),
              ),
            ],
            selected: {section},
            onSelectionChanged: (value) =>
                setState(() => section = value.first),
          ),
          const SizedBox(height: 20),
          if (section == 'notes')
            notes.when(
              data: (items) => items.isEmpty
                  ? const _EmptyCollection(
                      icon: Icons.edit_note_rounded,
                      message: 'Aún no tienes notas.',
                    )
                  : Column(
                      children: [
                        for (final note in items)
                          _NoteCard(
                            reference: note.reference,
                            body: note.body,
                            date: _shortDate(note.updatedAt),
                            onDelete: () async {
                              await ref
                                  .read(databaseProvider)
                                  .deleteNote(note.id);
                              ref.invalidate(syncProvider);
                            },
                          ),
                      ],
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('No se pudieron cargar: $error'),
            )
          else
            favorites.when(
              data: (items) => items.isEmpty
                  ? const _EmptyCollection(
                      icon: Icons.bookmark_outline_rounded,
                      message: 'Aún no tienes favoritos.',
                    )
                  : Column(
                      children: [
                        for (final verse in items)
                          Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(18),
                              title: Text(verse.reference),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(verse.body),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                final book = bibleBooks.firstWhere(
                                  (item) => item.code == verse.bookCode,
                                );
                                ref
                                    .read(readerLocationProvider.notifier)
                                    .goTo(book, verse.chapter);
                                context.go('/reader');
                              },
                            ),
                          ),
                      ],
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('No se pudieron cargar: $error'),
            ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.reference,
    required this.body,
    required this.date,
    required this.onDelete,
  });
  final String reference;
  final String body;
  final String date;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(child: Icon(Icons.edit_note_rounded)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reference,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(date),
                    IconButton(
                      tooltip: 'Eliminar nota',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(body, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 42),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    ),
  );
}

String _shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

Future<void> showReadingSettings(BuildContext context, WidgetRef ref) async {
  final database = ref.read(databaseProvider);
  var goal = int.tryParse(await database.getSetting('daily_goal') ?? '') ?? 10;
  final savedReminder = await database.getSetting('reminder_time');
  var reminderEnabled = savedReminder != null;
  final parts = savedReminder?.split(':');
  var reminderTime = TimeOfDay(
    hour: int.tryParse(parts?.first ?? '') ?? 20,
    minute: int.tryParse(parts?.last ?? '') ?? 0,
  );
  if (!context.mounted) return;

  final result = await showDialog<(int, bool, TimeOfDay)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Meta y recordatorio'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: goal,
                decoration: const InputDecoration(
                  labelText: 'Meta diaria de versículos',
                ),
                items: [
                  for (final value in const [5, 10, 15, 20, 30])
                    DropdownMenuItem(value: value, child: Text('$value')),
                ],
                onChanged: (value) =>
                    setDialogState(() => goal = value ?? goal),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recordatorio diario'),
                value: reminderEnabled,
                onChanged: (value) =>
                    setDialogState(() => reminderEnabled = value),
              ),
              if (reminderEnabled)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hora'),
                  trailing: Text(reminderTime.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: reminderTime,
                    );
                    if (picked != null) {
                      setDialogState(() => reminderTime = picked);
                    }
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, (goal, reminderEnabled, reminderTime)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  if (result == null) return;

  await database.setDailyGoal(result.$1);
  ref.invalidate(syncProvider);
  try {
    if (result.$2) {
      await reminderService.scheduleDaily(result.$3.hour, result.$3.minute);
      await database.setSetting(
        'reminder_time',
        '${result.$3.hour.toString().padLeft(2, '0')}:'
            '${result.$3.minute.toString().padLeft(2, '0')}',
      );
    } else {
      await reminderService.cancel();
      await database.setSetting('reminder_time', null);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preferencias guardadas')));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo programar el recordatorio: $error')),
      );
    }
  }
}
