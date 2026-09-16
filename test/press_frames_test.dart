import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feral_stamp/main.dart';

/// Renders the press at fixed points on the timeline.
///
/// Driving this through a browser is unreliable (synthetic clicks and key
/// events do not consistently reach the Flutter canvas), so the frames are
/// rendered here instead. Regenerate with:
///
///     flutter test --update-goldens test/press_frames_test.dart
void main() {
  const marks = <int>[0, 250, 500, 800, 900, 950, 1150, 1400, 1750, 2100];

  testWidgets('press timeline', tags: 'goldens', (tester) async {
    // The test binding flattens every blur into a solid shape for
    // determinism. These frames exist to be looked at, so draw the real thing.
    debugDisableShadows = false;

    tester.view.physicalSize = const Size(1000, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FeralStampApp());
    await tester.tap(find.text('Mark as paid'));
    await tester.pump();

    var elapsed = 0;
    for (final at in marks) {
      await tester.pump(Duration(milliseconds: at - elapsed));
      elapsed = at;
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/press_${at.toString().padLeft(4, '0')}.png'),
      );
    }

    await tester.pumpAndSettle();
    // Restore before the binding's post-test invariant check, which runs
    // ahead of any tearDown.
    debugDisableShadows = true;
  });
}
