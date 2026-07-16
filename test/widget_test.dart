import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen_biblia/adaptive_shell.dart';
import 'package:lumen_biblia/app.dart';
import 'package:lumen_biblia/bible_catalog.dart';
import 'package:lumen_biblia/bible_providers.dart';
import 'package:lumen_biblia/backend.dart';
import 'package:lumen_biblia/database.dart';
import 'package:lumen_biblia/screens.dart';

List<Override> emptyUserDataOverrides() => [
  readingActivityProvider.overrideWith((ref) => Stream.value(const [])),
  notesProvider.overrideWith((ref) => Stream.value(const [])),
  versePreferencesProvider.overrideWith((ref) => Stream.value(const [])),
  favoritesProvider.overrideWith((ref) => Stream.value(const [])),
  assistantConversationsProvider.overrideWith((ref) => Stream.value(const [])),
  dailyGoalProvider.overrideWith((ref) => Stream.value(10)),
  lastReaderLocationProvider.overrideWith(
    (ref) async => ReaderLocation(bibleBooks.first, 1),
  ),
  lastReadingPreviewProvider.overrideWith(
    (ref) async => ReadingPreview(
      ReaderLocation(bibleBooks.first, 1),
      'En el principio creó Dios los cielos y la tierra.',
    ),
  ),
];

void main() {
  test('breakpoints are deterministic', () {
    expect(windowClassFor(375), WindowClass.compact);
    expect(windowClassFor(599), WindowClass.compact);
    expect(windowClassFor(600), WindowClass.medium);
    expect(windowClassFor(1023), WindowClass.medium);
    expect(windowClassFor(1024), WindowClass.expanded);
    expect(windowClassFor(1440), WindowClass.expanded);
  });

  test('Bible references accept books, verses and ranges', () {
    expect(parseBibleReference('Juan 3:16')?.label, 'Juan 3:16');
    expect(
      parseBibleReference('1 Corintios 13:4-7')?.label,
      '1 Corintios 13:4–7',
    );
    expect(parseBibleReference('Salmos 151'), isNull);
  });

  test('Bible categories cover all books once in canonical order', () {
    final oldBooks = oldTestamentCategories.expand((item) => item.books);
    final newBooks = newTestamentCategories.expand((item) => item.books);
    final grouped = [...oldBooks, ...newBooks];

    expect(oldBooks, hasLength(39));
    expect(newBooks, hasLength(27));
    expect(grouped, bibleBooks);
    expect(grouped.map((book) => book.code).toSet(), hasLength(66));
  });

  test('stored reader locations are validated', () {
    expect(parseStoredReaderLocation('JOH:3').book.name, 'Juan');
    expect(parseStoredReaderLocation('JOH:3').chapter, 3);
    expect(parseStoredReaderLocation('PSA:151').book, bibleBooks.first);
    expect(parseStoredReaderLocation('not-a-location').chapter, 1);
  });

  test('reader controller persists chapters across book boundaries', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });

    await container
        .read(readerViewProvider.notifier)
        .openChapter(bibleBooks.first, 50);
    await container.read(readerViewProvider.notifier).moveChapter(1);

    final location = container.read(readerLocationProvider);
    expect(location.book.code, 'EXO');
    expect(location.chapter, 1);
    expect(await database.getSetting('last_reader_location'), 'EXO:1');
  });

  test('reading stats calculate totals and streaks', () {
    final createdAt = DateTime(2026, 7, 15);
    final entries = [
      for (final item in [
        (1, '2026-07-13'),
        (2, '2026-07-14'),
        (3, '2026-07-15'),
        (4, '2026-07-15'),
      ])
        ReadingEntry(
          id: item.$1,
          bookCode: 'JOH',
          chapter: 3,
          verse: item.$1,
          readDay: item.$2,
          createdAt: createdAt,
        ),
    ];

    final stats = calculateReadingStats(entries, DateTime(2026, 7, 16));
    expect(stats.total, 4);
    expect(stats.today, 0);
    expect(stats.currentStreak, 3);
    expect(stats.bestStreak, 3);
  });

  test('assistant parser only returns text deltas', () {
    expect(
      parseAssistantDelta(
        'data: {"type":"response.output_text.delta","delta":"Hola"}',
      ),
      'Hola',
    );
    expect(parseAssistantDelta('data: {"type":"response.completed"}'), isNull);
    expect(
      () => parseAssistantDelta(
        'data: {"type":"error","error":{"message":"falló"}}',
      ),
      throwsStateError,
    );
  });

  for (final testCase in [
    (375.0, 'compact-navigation'),
    (430.0, 'compact-navigation'),
    (800.0, 'medium-navigation'),
    (1024.0, 'expanded-navigation'),
    (1440.0, 'expanded-navigation'),
  ]) {
    testWidgets('renders ${testCase.$2} at ${testCase.$1.toInt()}px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(testCase.$1, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: emptyUserDataOverrides(),
          child: const LumenApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key(testCase.$2)), findsOneWidget);
      expect(find.text('Buenos días'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('assistant passage fits a compact screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: emptyUserDataOverrides(),
        child: const MaterialApp(
          home: AssistantScreen(
            passage: AssistantPassage(
              reference: 'Juan 3:16',
              text: '16 Porque de tal manera amó Dios al mundo.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Juan 3:16\n16 Porque de tal manera amó Dios al mundo.'),
      findsOneWidget,
    );
    expect(find.text('Inicia sesión para preguntar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [393.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('Bible catalog fits at ${width.toInt()}px', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: emptyUserDataOverrides(),
          child: const MaterialApp(home: ReaderScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Antiguo Testamento'), findsOneWidget);
      expect(find.text('Nuevo Testamento'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('compact Bible navigation follows books chapters and reader', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyUserDataOverrides(),
          databaseProvider.overrideWithValue(database),
          chapterVersesProvider.overrideWith(
            (ref) => Stream.value(const [
              BibleVerse(
                id: 'JOH.3.16',
                canonOrder: 42,
                bookCode: 'JOH',
                chapter: 3,
                verse: 16,
                endVerse: null,
                reference: 'Juan 3:16',
                body: 'Porque de tal manera amó Dios al mundo.',
              ),
            ]),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biblia'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Antiguo Testamento'), findsOneWidget);
    expect(find.textContaining('Porque de tal manera'), findsNothing);

    await tester.tap(find.text('Nuevo Testamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('book-JOH')));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona un capítulo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chapter-3')));
    await tester.pumpAndSettle();
    expect(find.text('Juan'), findsOneWidget);
    expect(find.textContaining('Porque de tal manera'), findsWidgets);

    await tester.tap(find.byKey(const Key('reader-back-chapters')));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona un capítulo'), findsOneWidget);
    expect(find.textContaining('Porque de tal manera'), findsNothing);

    await tester.tap(find.byKey(const Key('chapters-back-books')));
    await tester.pumpAndSettle();
    expect(find.text('Antiguo Testamento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
