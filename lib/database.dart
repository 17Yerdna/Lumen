import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'bible_catalog.dart';

part 'database.g.dart';

@DataClassName('BibleVerse')
class BibleVerses extends Table {
  TextColumn get id => text()();
  IntColumn get canonOrder => integer()();
  TextColumn get bookCode => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  IntColumn get endVerse => integer().nullable()();
  TextColumn get reference => text()();
  TextColumn get body => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('ReadingEntry')
class ReadingActivities extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bookCode => text()();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get readDay => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {bookCode, chapter, verse, readDay},
  ];
}

@DataClassName('VersePreference')
class VersePreferences extends Table {
  TextColumn get verseId => text()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  IntColumn get highlightColor => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {verseId};
}

@DataClassName('UserNote')
class UserNotes extends Table {
  TextColumn get id => text()();
  TextColumn get bookCode => text()();
  IntColumn get chapter => integer()();
  IntColumn get startVerse => integer()();
  IntColumn get endVerse => integer()();
  TextColumn get reference => text()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    BibleVerses,
    AppSettings,
    ReadingActivities,
    VersePreferences,
    UserNotes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'lumen_biblia'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement('''
        CREATE VIRTUAL TABLE bible_verses_fts USING fts5(
          id UNINDEXED,
          reference UNINDEXED,
          body,
          tokenize = 'unicode61 remove_diacritics 2'
        )
      ''');
      await customStatement('''
        CREATE TRIGGER bible_verses_after_insert
        AFTER INSERT ON bible_verses BEGIN
          INSERT INTO bible_verses_fts(id, reference, body)
          VALUES (new.id, new.reference, new.body);
        END
      ''');
      await customStatement('''
        CREATE TRIGGER bible_verses_after_delete
        AFTER DELETE ON bible_verses BEGIN
          DELETE FROM bible_verses_fts WHERE id = old.id;
        END
      ''');
      await customStatement('''
        CREATE TRIGGER bible_verses_after_update
        AFTER UPDATE ON bible_verses BEGIN
          DELETE FROM bible_verses_fts WHERE id = old.id;
          INSERT INTO bible_verses_fts(id, reference, body)
          VALUES (new.id, new.reference, new.body);
        END
      ''');
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(readingActivities);
        await migrator.createTable(versePreferences);
        await migrator.createTable(userNotes);
      }
    },
  );

  Future<void> ensureBibleSeeded() async {
    final currentVersion = await (select(
      appSettings,
    )..where((row) => row.key.equals('bible_seed_version'))).getSingleOrNull();
    if (currentVersion?.value == 'rv1909-v1') return;

    final source = await rootBundle.loadString(
      'assets/bible/spaRV1909_vpl.txt',
    );
    await importBibleText(source);
  }

  Future<void> importBibleText(String source) async {
    final companions = <BibleVersesCompanion>[];
    final pattern = RegExp(r'^([A-Z0-9]{3})\s+(\d+):(\d+)(?:-(\d+))?\s+(.+)$');

    for (final line in const LineSplitter().convert(source)) {
      final match = pattern.firstMatch(line);
      if (match == null) continue;
      final code = match.group(1)!;
      final chapter = int.parse(match.group(2)!);
      final verse = int.parse(match.group(3)!);
      final endVerse = int.tryParse(match.group(4) ?? '');
      final body = match.group(5)!.trim();
      final bookIndex = bibleBooks.indexWhere((book) => book.code == code);
      if (bookIndex < 0) continue;
      final book = bibleBooks[bookIndex];
      final verseLabel = endVerse == null || endVerse == verse
          ? '$verse'
          : '$verse–$endVerse';

      companions.add(
        BibleVersesCompanion.insert(
          id: '$code.$chapter.$verse',
          canonOrder: bookIndex,
          bookCode: code,
          chapter: chapter,
          verse: verse,
          endVerse: Value(endVerse),
          reference: '${book.name} $chapter:$verseLabel',
          body: body,
        ),
      );
    }

    await transaction(() async {
      await delete(bibleVerses).go();
      await customStatement('DELETE FROM bible_verses_fts');
      const chunkSize = 1000;
      for (var start = 0; start < companions.length; start += chunkSize) {
        final end = start + chunkSize < companions.length
            ? start + chunkSize
            : companions.length;
        await batch((batch) {
          batch.insertAll(
            bibleVerses,
            companions.sublist(start, end),
            mode: InsertMode.insertOrReplace,
          );
        });
      }
      await into(appSettings).insertOnConflictUpdate(
        const AppSettingsCompanion(
          key: Value('bible_seed_version'),
          value: Value('rv1909-v1'),
        ),
      );
    });
  }

  Stream<List<BibleVerse>> watchChapter(String bookCode, int chapter) {
    return (select(bibleVerses)
          ..where(
            (row) =>
                row.bookCode.equals(bookCode) & row.chapter.equals(chapter),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.verse)]))
        .watch();
  }

  Future<List<BibleVerse>> getReference(BibleReference reference) {
    final query = select(bibleVerses)
      ..where(
        (row) =>
            row.bookCode.equals(reference.book.code) &
            row.chapter.equals(reference.chapter),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.verse)]);
    if (reference.startVerse != null) {
      final end = reference.endVerse ?? reference.startVerse!;
      query.where(
        (row) =>
            row.verse.isBiggerOrEqualValue(reference.startVerse!) &
            row.verse.isSmallerOrEqualValue(end),
      );
    }
    return query.get();
  }

  Future<List<BibleVerse>> search(String input, {int limit = 50}) async {
    final reference = parseBibleReference(input);
    if (reference != null) return getReference(reference);

    final tokens = normalizeBibleText(input)
        .replaceAll(RegExp(r'[^a-z0-9ñ ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length >= 2)
        .take(8)
        .toList();
    if (tokens.isEmpty) return const [];
    final ftsQuery = tokens.map((token) => '"$token"*').join(' AND ');

    final rows = await customSelect(
      '''
        SELECT v.id, v.canon_order, v.book_code, v.chapter, v.verse,
               v.end_verse, v.reference, v.body
        FROM bible_verses_fts f
        JOIN bible_verses v ON v.id = f.id
        WHERE bible_verses_fts MATCH ?
        ORDER BY rank, v.canon_order, v.chapter, v.verse
        LIMIT ?
      ''',
      variables: [Variable.withString(ftsQuery), Variable.withInt(limit)],
      readsFrom: {bibleVerses},
    ).get();

    return rows
        .map(
          (row) => BibleVerse(
            id: row.read<String>('id'),
            canonOrder: row.read<int>('canon_order'),
            bookCode: row.read<String>('book_code'),
            chapter: row.read<int>('chapter'),
            verse: row.read<int>('verse'),
            endVerse: row.readNullable<int>('end_verse'),
            reference: row.read<String>('reference'),
            body: row.read<String>('body'),
          ),
        )
        .toList();
  }

  Future<void> markRead(
    String bookCode,
    int chapter,
    Iterable<int> verses,
  ) async {
    final now = DateTime.now();
    final day = _dayKey(now);
    await batch((batch) {
      for (final verse in verses) {
        batch.insert(
          readingActivities,
          ReadingActivitiesCompanion.insert(
            bookCode: bookCode,
            chapter: chapter,
            verse: verse,
            readDay: day,
            createdAt: Value(now),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<void> saveNote(
    BookInfo book,
    int chapter,
    Iterable<int> verses,
    String body,
  ) async {
    final sorted = verses.toList()..sort();
    if (sorted.isEmpty || body.trim().isEmpty) return;
    final start = sorted.first;
    final end = sorted.last;
    final now = DateTime.now();
    final range = start == end ? '$start' : '$start–$end';
    await into(userNotes).insert(
      UserNotesCompanion.insert(
        id: const Uuid().v4(),
        bookCode: book.code,
        chapter: chapter,
        startVerse: start,
        endVerse: end,
        reference: '${book.name} $chapter:$range',
        body: body.trim(),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> setFavorite(Iterable<String> verseIds, bool value) async {
    final now = DateTime.now();
    await batch((batch) {
      for (final verseId in verseIds) {
        batch.insert(
          versePreferences,
          VersePreferencesCompanion.insert(
            verseId: verseId,
            favorite: Value(value),
            updatedAt: Value(now),
          ),
          onConflict: DoUpdate(
            (_) => VersePreferencesCompanion(
              favorite: Value(value),
              updatedAt: Value(now),
            ),
          ),
        );
      }
    });
  }

  Future<void> setHighlight(Iterable<String> verseIds, int? color) async {
    final now = DateTime.now();
    await batch((batch) {
      for (final verseId in verseIds) {
        batch.insert(
          versePreferences,
          VersePreferencesCompanion.insert(
            verseId: verseId,
            highlightColor: Value(color),
            updatedAt: Value(now),
          ),
          onConflict: DoUpdate(
            (_) => VersePreferencesCompanion(
              highlightColor: Value(color),
              updatedAt: Value(now),
            ),
          ),
        );
      }
    });
  }

  Stream<List<ReadingEntry>> watchReadingActivity() => (select(
    readingActivities,
  )..orderBy([(row) => OrderingTerm.desc(row.createdAt)])).watch();

  Stream<List<VersePreference>> watchPreferences() =>
      select(versePreferences).watch();

  Stream<List<UserNote>> watchNotes() => (select(
    userNotes,
  )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).watch();

  Stream<List<BibleVerse>> watchFavorites() =>
      customSelect(
        '''
          SELECT v.id, v.canon_order, v.book_code, v.chapter, v.verse,
                 v.end_verse, v.reference, v.body
          FROM verse_preferences p
          JOIN bible_verses v ON v.id = p.verse_id
          WHERE p.favorite = 1
          ORDER BY p.updated_at DESC
        ''',
        readsFrom: {versePreferences, bibleVerses},
      ).watch().map(
        (rows) => rows
            .map(
              (row) => BibleVerse(
                id: row.read<String>('id'),
                canonOrder: row.read<int>('canon_order'),
                bookCode: row.read<String>('book_code'),
                chapter: row.read<int>('chapter'),
                verse: row.read<int>('verse'),
                endVerse: row.readNullable<int>('end_verse'),
                reference: row.read<String>('reference'),
                body: row.read<String>('body'),
              ),
            )
            .toList(),
      );

  Future<void> deleteNote(String id) =>
      (delete(userNotes)..where((row) => row.id.equals(id))).go();

  Future<String?> getSetting(String key) async => (await (select(
    appSettings,
  )..where((row) => row.key.equals(key))).getSingleOrNull())?.value;

  Stream<String?> watchSetting(String key) =>
      (select(appSettings)..where((row) => row.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  Future<void> setSetting(String key, String? value) async {
    if (value == null) {
      await (delete(appSettings)..where((row) => row.key.equals(key))).go();
      return;
    }
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(key: Value(key), value: Value(value)),
    );
  }
}

String _dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
