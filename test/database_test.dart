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
    await database.close();
  });
}
