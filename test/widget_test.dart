import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feral_stamp/main.dart';
import 'package:feral_stamp/src/stamp_sound.dart';
import 'package:feral_stamp/src/invoice.dart';
import 'package:feral_stamp/src/stamp_page.dart';

void main() {
  testWidgets('stamping prints the date onto the invoice', (tester) async {
    // The scene plus its controls is taller than the default 800x600 surface,
    // and an off-screen button cannot be tapped.
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(FeralStampApp(sound: StampSound.silent()));

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

  testWidgets('holding the button stamps VOID instead of the label', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(FeralStampApp(sound: StampSound.silent()));
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

  testWidgets('the camera tilts the far edge away from the viewer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(FeralStampApp(sound: StampSound.silent()));
    await tester.tap(find.text('Mark as paid'));
    await tester.pump();
    // Part way through the 800ms camera tilt.
    await tester.pump(const Duration(milliseconds: 400));

    final transform = tester.widget<Transform>(find.byKey(cameraKey));
    final m = transform.transform;

    // Points are relative to the paper's centre. The reference page is narrow
    // at the top and wide at the bottom, so a point above centre must project
    // closer to the middle than the matching point below it.
    final top = MatrixUtils.transformPoint(m, const Offset(0, -100));
    final bottom = MatrixUtils.transformPoint(m, const Offset(0, 100));

    expect(
      top.dy.abs(),
      lessThan(100),
      reason: 'the top edge should recede, not grow',
    );
    expect(
      top.dy.abs(),
      lessThan(bottom.dy.abs()),
      reason: 'the top edge should be further away than the bottom',
    );

    await tester.pumpAndSettle();
  });
}
