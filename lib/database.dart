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

@DataClassName('AssistantConversation')
class AssistantConversations extends Table {
  TextColumn get id => text()();
  TextColumn get reference => text()();
  TextColumn get passageText => text()();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SyncItem')
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get recordKey => text()();
  TextColumn get payload => text()();
  BoolColumn get isDelete => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {entity, recordKey},
  ];
}

@DriftDatabase(
  tables: [
    BibleVerses,
    AppSettings,
    ReadingActivities,
    VersePreferences,
    UserNotes,
    AssistantConversations,
    SyncOutbox,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'lumen_biblia'));

  @override
  int get schemaVersion => 4;

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
      if (from < 3) await migrator.createTable(syncOutbox);
      if (from < 4) await migrator.createTable(assistantConversations);
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
        batch.insert(
          syncOutbox,
          _syncItem('reading_activity', '$bookCode.$chapter.$verse.$day', {
            'book_code': bookCode,
            'chapter': chapter,
            'verse': verse,
            'read_day': day,
            'created_at': now.toUtc().toIso8601String(),
          }),
          mode: InsertMode.insertOrReplace,
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
    final id = const Uuid().v4();
    final range = start == end ? '$start' : '$start–$end';
    final reference = '${book.name} $chapter:$range';
    await batch((batch) {
      batch.insert(
        userNotes,
        UserNotesCompanion.insert(
          id: id,
          bookCode: book.code,
          chapter: chapter,
          startVerse: start,
          endVerse: end,
          reference: reference,
          body: body.trim(),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      batch.insert(
        syncOutbox,
        _syncItem('notes', id, {
          'id': id,
          'book_code': book.code,
          'chapter': chapter,
          'start_verse': start,
          'end_verse': end,
          'reference': reference,
          'body': body.trim(),
          'created_at': now.toUtc().toIso8601String(),
          'updated_at': now.toUtc().toIso8601String(),
        }),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> setFavorite(Iterable<String> verseIds, bool value) async {
    final ids = verseIds.toList();
    final now = DateTime.now();
    await batch((batch) {
      for (final verseId in ids) {
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
    await _queuePreferences(ids);
  }

  Future<void> setHighlight(Iterable<String> verseIds, int? color) async {
    final ids = verseIds.toList();
    final now = DateTime.now();
    await batch((batch) {
      for (final verseId in ids) {
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
    await _queuePreferences(ids);
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

  Future<void> deleteNote(String id) async {
    await batch((batch) {
      batch.deleteWhere(userNotes, (row) => row.id.equals(id));
      batch.insert(
        syncOutbox,
        _syncItem('notes', id, {'id': id}, isDelete: true),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

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

  Future<void> setDailyGoal(int goal) async {
    await batch((batch) {
      batch.insert(
        appSettings,
        AppSettingsCompanion(
          key: const Value('daily_goal'),
          value: Value('$goal'),
        ),
        mode: InsertMode.insertOrReplace,
      );
      batch.insert(
        syncOutbox,
        _syncItem('profiles', 'self', {'daily_goal': goal}),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<Map<String, Object?>> exportUserData() async {
    final activities = await select(readingActivities).get();
    final preferences = await select(versePreferences).get();
    final notes = await select(userNotes).get();
    final conversations = await select(assistantConversations).get();
    final settings = await (select(
      appSettings,
    )..where((row) => row.key.isIn(['daily_goal', 'reminder_time']))).get();
    return {
      'format': 'lumen-biblia-export-v1',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'settings': {for (final row in settings) row.key: row.value},
      'reading_activity': [
        for (final row in activities)
          {
            'book_code': row.bookCode,
            'chapter': row.chapter,
            'verse': row.verse,
            'read_day': row.readDay,
            'created_at': row.createdAt.toUtc().toIso8601String(),
          },
      ],
      'verse_preferences': [
        for (final row in preferences)
          {
            'verse_id': row.verseId,
            'favorite': row.favorite,
            'highlight_color': row.highlightColor,
            'updated_at': row.updatedAt.toUtc().toIso8601String(),
          },
      ],
      'notes': [
        for (final row in notes)
          {
            'id': row.id,
            'reference': row.reference,
            'body': row.body,
            'created_at': row.createdAt.toUtc().toIso8601String(),
            'updated_at': row.updatedAt.toUtc().toIso8601String(),
          },
      ],
      'assistant_conversations': [
        for (final row in conversations)
          {
            'id': row.id,
            'reference': row.reference,
            'passage_text': row.passageText,
            'question': row.question,
            'answer': row.answer,
            'created_at': row.createdAt.toUtc().toIso8601String(),
          },
      ],
    };
  }

  Future<String> exportUserDataJson() async =>
      const JsonEncoder.withIndent('  ').convert(await exportUserData());

  Future<String> exportUserDataMarkdown() async {
    final data = await exportUserData();
    final notes = (data['notes'] as List).cast<Map<String, Object?>>();
    final activity = (data['reading_activity'] as List)
        .cast<Map<String, Object?>>();
    final conversations = (data['assistant_conversations'] as List)
        .cast<Map<String, Object?>>();
    final output = StringBuffer()
      ..writeln('# Exportación de Lumen Biblia')
      ..writeln()
      ..writeln('Generada: ${data['exported_at']}')
      ..writeln()
      ..writeln('## Actividad de lectura')
      ..writeln();
    for (final row in activity) {
      output.writeln(
        '- ${row['read_day']}: ${row['book_code']} '
        '${row['chapter']}:${row['verse']}',
      );
    }
    output
      ..writeln()
      ..writeln('## Notas')
      ..writeln();
    for (final row in notes) {
      output
        ..writeln('### ${row['reference']}')
        ..writeln()
        ..writeln(row['body'])
        ..writeln();
    }
    output
      ..writeln('## Consultas al asistente')
      ..writeln();
    for (final row in conversations) {
      output
        ..writeln('### ${row['reference']}')
        ..writeln()
        ..writeln('**Pregunta:** ${row['question']}')
        ..writeln()
        ..writeln(row['answer'])
        ..writeln();
    }
    return output.toString();
  }

  Future<void> clearPersonalData() => transaction(() async {
    await delete(readingActivities).go();
    await delete(versePreferences).go();
    await delete(userNotes).go();
    await delete(assistantConversations).go();
    await delete(syncOutbox).go();
    await (delete(
      appSettings,
    )..where((row) => row.key.isNotValue('bible_seed_version'))).go();
  });

  Stream<List<AssistantConversation>> watchAssistantConversations() =>
      (select(assistantConversations)
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
            ..limit(20))
          .watch();

  Future<void> saveAssistantConversation({
    required String reference,
    required String passageText,
    required String question,
    required String answer,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final conversation = AssistantConversationsCompanion.insert(
      id: id,
      reference: reference,
      passageText: passageText,
      question: question,
      answer: answer,
      createdAt: Value(now),
    );
    await batch((batch) {
      batch.insert(assistantConversations, conversation);
      batch.insert(
        syncOutbox,
        _syncItem('assistant_conversations', id, {
          'id': id,
          'reference': reference,
          'passage_text': passageText,
          'question': question,
          'answer': answer,
          'created_at': now.toUtc().toIso8601String(),
        }),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> enqueueAllForSync() async {
    final activities = await select(readingActivities).get();
    final preferences = await select(versePreferences).get();
    final notes = await select(userNotes).get();
    final conversations = await select(assistantConversations).get();
    final goal = int.tryParse(await getSetting('daily_goal') ?? '');
    await batch((batch) {
      for (final entry in activities) {
        batch.insert(
          syncOutbox,
          _syncItem(
            'reading_activity',
            '${entry.bookCode}.${entry.chapter}.${entry.verse}.${entry.readDay}',
            {
              'book_code': entry.bookCode,
              'chapter': entry.chapter,
              'verse': entry.verse,
              'read_day': entry.readDay,
              'created_at': entry.createdAt.toUtc().toIso8601String(),
            },
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
      for (final preference in preferences) {
        batch.insert(
          syncOutbox,
          _preferenceSyncItem(preference),
          mode: InsertMode.insertOrReplace,
        );
      }
      for (final note in notes) {
        batch.insert(
          syncOutbox,
          _noteSyncItem(note),
          mode: InsertMode.insertOrReplace,
        );
      }
      for (final conversation in conversations) {
        batch.insert(
          syncOutbox,
          _conversationSyncItem(conversation),
          mode: InsertMode.insertOrReplace,
        );
      }
      if (goal != null) {
        batch.insert(
          syncOutbox,
          _syncItem('profiles', 'self', {'daily_goal': goal}),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<SyncItem>> pendingSyncItems() =>
      (select(syncOutbox)..orderBy([(row) => OrderingTerm.asc(row.id)])).get();

  Future<void> removeSyncItem(int id) =>
      (delete(syncOutbox)..where((row) => row.id.equals(id))).go();

  Future<void> mergeRemoteReadings(List<Map<String, dynamic>> rows) async {
    await batch((batch) {
      for (final row in rows) {
        batch.insert(
          readingActivities,
          ReadingActivitiesCompanion.insert(
            bookCode: row['book_code'] as String,
            chapter: row['chapter'] as int,
            verse: row['verse'] as int,
            readDay: row['read_day'] as String,
            createdAt: Value(DateTime.parse(row['created_at'] as String)),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<void> mergeRemotePreferences(List<Map<String, dynamic>> rows) async {
    await batch((batch) {
      for (final row in rows) {
        batch.insert(
          versePreferences,
          VersePreferencesCompanion.insert(
            verseId: row['verse_id'] as String,
            favorite: Value(row['favorite'] as bool? ?? false),
            highlightColor: Value(row['highlight_color'] as int?),
            updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> mergeRemoteNotes(List<Map<String, dynamic>> rows) async {
    await batch((batch) {
      for (final row in rows) {
        batch.insert(
          userNotes,
          UserNotesCompanion.insert(
            id: row['id'] as String,
            bookCode: row['book_code'] as String,
            chapter: row['chapter'] as int,
            startVerse: row['start_verse'] as int,
            endVerse: row['end_verse'] as int,
            reference: row['reference'] as String,
            body: row['body'] as String,
            createdAt: Value(DateTime.parse(row['created_at'] as String)),
            updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<void> mergeRemoteConversations(List<Map<String, dynamic>> rows) async {
    await batch((batch) {
      for (final row in rows) {
        batch.insert(
          assistantConversations,
          AssistantConversationsCompanion.insert(
            id: row['id'] as String,
            reference: row['reference'] as String,
            passageText: row['passage_text'] as String,
            question: row['question'] as String,
            answer: row['answer'] as String,
            createdAt: Value(DateTime.parse(row['created_at'] as String)),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<void> applyRemoteDailyGoal(int? goal) =>
      setSetting('daily_goal', goal == null ? null : '$goal');

  Future<void> _queuePreferences(Iterable<String> ids) async {
    final preferences = await (select(
      versePreferences,
    )..where((row) => row.verseId.isIn(ids))).get();
    await batch((batch) {
      for (final preference in preferences) {
        batch.insert(
          syncOutbox,
          _preferenceSyncItem(preference),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  SyncOutboxCompanion _preferenceSyncItem(VersePreference preference) =>
      _syncItem('verse_preferences', preference.verseId, {
        'verse_id': preference.verseId,
        'favorite': preference.favorite,
        'highlight_color': preference.highlightColor,
        'updated_at': preference.updatedAt.toUtc().toIso8601String(),
      });

  SyncOutboxCompanion _noteSyncItem(UserNote note) =>
      _syncItem('notes', note.id, {
        'id': note.id,
        'book_code': note.bookCode,
        'chapter': note.chapter,
        'start_verse': note.startVerse,
        'end_verse': note.endVerse,
        'reference': note.reference,
        'body': note.body,
        'created_at': note.createdAt.toUtc().toIso8601String(),
        'updated_at': note.updatedAt.toUtc().toIso8601String(),
      });

  SyncOutboxCompanion _conversationSyncItem(
    AssistantConversation conversation,
  ) => _syncItem('assistant_conversations', conversation.id, {
    'id': conversation.id,
    'reference': conversation.reference,
    'passage_text': conversation.passageText,
    'question': conversation.question,
    'answer': conversation.answer,
    'created_at': conversation.createdAt.toUtc().toIso8601String(),
  });

  SyncOutboxCompanion _syncItem(
    String entity,
    String key,
    Map<String, Object?> payload, {
    bool isDelete = false,
  }) => SyncOutboxCompanion.insert(
    entity: entity,
    recordKey: key,
    payload: jsonEncode(payload),
    isDelete: Value(isDelete),
  );
}

String _dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
