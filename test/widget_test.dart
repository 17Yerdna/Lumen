import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen_biblia/adaptive_shell.dart';
import 'package:lumen_biblia/app.dart';
import 'package:lumen_biblia/bible_catalog.dart';
import 'package:lumen_biblia/bible_providers.dart';
import 'package:lumen_biblia/database.dart';

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

  for (final testCase in [
    (375.0, 'compact-navigation'),
    (800.0, 'medium-navigation'),
    (1440.0, 'expanded-navigation'),
  ]) {
    testWidgets('renders ${testCase.$2} at ${testCase.$1.toInt()}px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(testCase.$1, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: LumenApp()));
      await tester.pumpAndSettle();

      expect(find.byKey(Key(testCase.$2)), findsOneWidget);
      expect(find.text('Buenos días'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('compact navigation opens the reader', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

    expect(find.text('Juan'), findsOneWidget);
    expect(find.textContaining('Porque de tal manera'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
