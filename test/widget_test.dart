import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen_biblia/adaptive_shell.dart';
import 'package:lumen_biblia/app.dart';

void main() {
  test('breakpoints are deterministic', () {
    expect(windowClassFor(375), WindowClass.compact);
    expect(windowClassFor(599), WindowClass.compact);
    expect(windowClassFor(600), WindowClass.medium);
    expect(windowClassFor(1023), WindowClass.medium);
    expect(windowClassFor(1024), WindowClass.expanded);
    expect(windowClassFor(1440), WindowClass.expanded);
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

    await tester.pumpWidget(const ProviderScope(child: LumenApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biblia'));
    await tester.pumpAndSettle();

    expect(find.text('Juan'), findsOneWidget);
    expect(find.textContaining('Porque de tal manera'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
