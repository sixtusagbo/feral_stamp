import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feral_stamp/main.dart';
import 'package:feral_stamp/src/invoice.dart';

void main() {
  testWidgets('stamping prints the date onto the invoice', (tester) async {
    // The scene plus its controls is taller than the default 800x600 surface,
    // and an off-screen button cannot be tapped.
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FeralStampApp());

    // The picker is up; nothing is stamped yet.
    expect(find.text('Mark as paid'), findsOneWidget);
    expect(find.text('15 SEP 2026'), findsNothing);

    await tester.tap(find.text('Mark as paid'));
    await tester.pumpAndSettle();

    // The mark has landed and the toast offers an undo.
    expect(find.text('15 SEP 2026'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Mark as paid'), findsOneWidget);
    expect(find.text('15 SEP 2026'), findsNothing);
  });

  testWidgets('holding the button stamps VOID instead of the label',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FeralStampApp());
    await tester.longPress(find.text('Mark as paid'));
    await tester.pumpAndSettle();

    expect(find.text('VOID'), findsWidgets);
  });

  test('a day is clamped to the selected month', () {
    expect(daysInMonth(2026, 2), 28);
    expect(daysInMonth(2024, 2), 29);
    expect(daysInMonth(2026, 9), 30);
  });

  test('dates format the way the stamp prints them', () {
    final d = DateTime(2026, 9, 15);
    expect(d.stampLine, '15 SEP 2026');
    expect(d.shortLine, '15 Sep 2026');
    expect(d.longLine, 'Tuesday, 15 September 2026');
  });
}
