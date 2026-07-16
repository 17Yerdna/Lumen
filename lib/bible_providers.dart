import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend.dart';
import 'bible_catalog.dart';
import 'database.dart';
import 'sync.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final authSessionProvider = StreamProvider<Session?>((ref) {
  final client = supabaseClient;
  if (client == null) return Stream.value(null);
  return client.auth.onAuthStateChange.map((state) => state.session);
});

final syncProvider = FutureProvider<void>((ref) async {
  final client = supabaseClient;
  final session = ref.watch(authSessionProvider).value;
  if (client == null || session == null) return;
  await syncDatabase(ref.watch(databaseProvider), client, session.user.id);
});

final bibleReadyProvider = FutureProvider<void>(
  (ref) => ref.watch(databaseProvider).ensureBibleSeeded(),
);

class ReaderLocation {
  const ReaderLocation(this.book, this.chapter);

  final BookInfo book;
  final int chapter;
}

class ReaderLocationController extends Notifier<ReaderLocation> {
  @override
  ReaderLocation build() => ReaderLocation(findBibleBook('Juan')!, 3);

  void goTo(BookInfo book, int chapter) {
    state = ReaderLocation(book, chapter);
  }

  void move(int offset) {
    var bookIndex = bibleBooks.indexOf(state.book);
    var chapter = state.chapter + offset;
    if (chapter < 1 && bookIndex > 0) {
      bookIndex--;
      chapter = bibleBooks[bookIndex].chapters;
    } else if (chapter > state.book.chapters &&
        bookIndex < bibleBooks.length - 1) {
      bookIndex++;
      chapter = 1;
    }
    state = ReaderLocation(
      bibleBooks[bookIndex],
      chapter.clamp(1, bibleBooks[bookIndex].chapters),
    );
  }
}

final readerLocationProvider =
    NotifierProvider<ReaderLocationController, ReaderLocation>(
      ReaderLocationController.new,
    );

final chapterVersesProvider = StreamProvider<List<BibleVerse>>((ref) async* {
  await ref.watch(bibleReadyProvider.future);
  final location = ref.watch(readerLocationProvider);
  yield* ref
      .watch(databaseProvider)
      .watchChapter(location.book.code, location.chapter);
});

final readingActivityProvider = StreamProvider<List<ReadingEntry>>(
  (ref) => ref.watch(databaseProvider).watchReadingActivity(),
);

final versePreferencesProvider = StreamProvider<List<VersePreference>>(
  (ref) => ref.watch(databaseProvider).watchPreferences(),
);

final notesProvider = StreamProvider<List<UserNote>>(
  (ref) => ref.watch(databaseProvider).watchNotes(),
);

final favoritesProvider = StreamProvider<List<BibleVerse>>(
  (ref) => ref.watch(databaseProvider).watchFavorites(),
);

final dailyGoalProvider = StreamProvider<int>(
  (ref) => ref
      .watch(databaseProvider)
      .watchSetting('daily_goal')
      .map((value) => int.tryParse(value ?? '') ?? 10),
);

class ReadingStats {
  const ReadingStats({
    required this.total,
    required this.today,
    required this.currentStreak,
    required this.bestStreak,
    required this.byDay,
  });

  final int total;
  final int today;
  final int currentStreak;
  final int bestStreak;
  final Map<String, int> byDay;
}

ReadingStats calculateReadingStats(
  Iterable<ReadingEntry> entries,
  DateTime now,
) {
  final byDay = <String, int>{};
  for (final entry in entries) {
    byDay.update(entry.readDay, (count) => count + 1, ifAbsent: () => 1);
  }
  final days = byDay.keys.toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final day in days) {
    final date = DateTime.parse(day);
    run = previous != null && date.difference(previous).inDays == 1
        ? run + 1
        : 1;
    if (run > best) best = run;
    previous = date;
  }

  var cursor = DateTime(now.year, now.month, now.day);
  if (!byDay.containsKey(_dayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var current = 0;
  while (byDay.containsKey(_dayKey(cursor))) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return ReadingStats(
    total: entries.length,
    today: byDay[_dayKey(now)] ?? 0,
    currentStreak: current,
    bestStreak: best,
    byDay: byDay,
  );
}

String _dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
