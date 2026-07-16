import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
    await database.close();
  });
}
