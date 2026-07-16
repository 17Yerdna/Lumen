import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen_biblia/bible_catalog.dart';
import 'package:lumen_biblia/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('imports and searches the packaged Bible', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final source = await rootBundle.loadString(
      'assets/bible/spaRV1909_vpl.txt',
    );
    await database.importBibleText(source);

    final chapter = await database.search('Juan 3');
    final phrase = await database.search('Dios es amor');
    expect(chapter, hasLength(36));
    expect(phrase, isNotEmpty);

    await database.markRead('JOH', 3, [16, 16]);
    await database.markRead('JOH', 3, [16]);
    await database.saveNote(findBibleBook('Juan')!, 3, [
      16,
      17,
    ], 'Una reflexión privada');
    await database.setFavorite(['JOH.3.16'], true);
    await database.setHighlight(['JOH.3.16'], 0xFFFFD166);
    await database.setDailyGoal(12);
    await database.saveAssistantConversation(
      reference: 'Juan 3:16',
      passageText: '16 Porque de tal manera amó Dios al mundo.',
      question: 'Explícalo.',
      answer: 'Una explicación guardada.',
    );

    expect(await database.watchReadingActivity().first, hasLength(1));
    expect(
      (await database.watchNotes().first).single.reference,
      'Juan 3:16–17',
    );
    expect((await database.watchFavorites().first).single.id, 'JOH.3.16');
    expect(
      (await database.watchPreferences().first).single.highlightColor,
      0xFFFFD166,
    );
    final pending = await database.pendingSyncItems();
    expect(pending.map((item) => item.entity).toSet(), {
      'reading_activity',
      'notes',
      'verse_preferences',
      'profiles',
      'assistant_conversations',
    });
    final preference = pending.singleWhere(
      (item) => item.entity == 'verse_preferences',
    );
    expect(jsonDecode(preference.payload), {
      'verse_id': 'JOH.3.16',
      'favorite': true,
      'highlight_color': 0xFFFFD166,
      'updated_at': isA<String>(),
    });
    expect(
      (await database.watchAssistantConversations().first).single.answer,
      'Una explicación guardada.',
    );
    await database.close();
  });
}
