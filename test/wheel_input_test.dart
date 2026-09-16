import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feral_stamp/main.dart';
import 'package:feral_stamp/src/stamp_sound.dart';

/// The wheels are the whole point of the component, and on web and desktop the
/// only way anyone reaches them is with a cursor. Flutter excludes mouse and
/// trackpad from `dragDevices` by default, which leaves them inert, so both
/// input kinds are pinned here.
void main() {
  for (final kind in const [
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  ]) {
    testWidgets('a $kind drag rolls the day wheel', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(FeralStampApp(sound: StampSound.silent()));
      expect(find.textContaining('15 September 2026'), findsOneWidget);

      await tester.drag(
        find.text('15').first,
        const Offset(0, -60),
        kind: kind,
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('15 September 2026'),
        findsNothing,
        reason: 'a $kind drag should have moved the day off 15',
      );
    });
  }
}
