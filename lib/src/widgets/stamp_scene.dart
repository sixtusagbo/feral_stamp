import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'invoice_sheet.dart';
import 'stamp_cube.dart';
import 'stamp_face.dart';
import 'unclamped.dart';

/// Identifies the perspective transform wrapping the paper, so tests can read
/// the camera matrix instead of eyeballing a screenshot.
const cameraKey = Key('stamp-camera');

/// The page and the stamp under one camera, driven by the five phase values.
///
/// There is only ever *one* stamp: the picker tips into 3D and becomes the
/// box. That continuity is the whole trick, so it must not be faked with a
/// crossfade between two separate widgets.
class StampScene extends StatelessWidget {
  const StampScene({
    super.key,
    required this.tilt,
    required this.press,
    required this.lift,
    required this.rise,
    required this.bleed,
    required this.date,
    required this.headText,
    required this.ink,
    required this.color,
    required this.interactive,
    required this.onDateChanged,
    this.toast,
  });

  /// Phase progress, each 0..1, from the page's timeline.
  final double tilt;
  final double press;
  final double lift;
  final double rise;
  final double bleed;

  final DateTime date;
  final String headText;

  /// What prints on the page.
  final Color ink;

  /// What the picker shows on its lid (VOID prints red regardless).
  final Color color;

  final bool interactive;
  final ValueChanged<DateTime> onDateChanged;

  /// Shown straddling the page's bottom edge while the stamp is landed.
  final Widget? toast;

  @override
  Widget build(BuildContext context) {
    // Tilt in, then back out again as the camera rises at the end.
    final t = tilt;
    final camera = (t - rise).clamp(0.0, 1.0);
    final angle = camera * 0.80;

    // Perspective comes in with the tilt so the box sits flat and undistorted
    // while it is still the picker.
    final perspective = 0.0009 * t;

    final camera3d = Matrix4.identity()
      ..setEntry(3, 2, perspective)
      ..rotateX(-angle);

    // The rubber rebounds off the paper, then the box accelerates away.
    final bounce =
        Curves.easeOutCubic.transform((lift * 3).clamp(0.0, 1.0)) * Beat.bounce;
    final settle = (1 - press) + bounce;
    final exit = Curves.easeInCubic.transform(lift);

    // The box is a real object on the page: it hovers above the mark along
    // the page's normal and descends onto it. Leaving is a screen-space rise
    // applied outside the camera, which is what the reference does.
    // The hover is high: about a third of the page's height in the reference,
    // so the 0.15s drop covers real distance and lands as a slam.
    const markOnPage = Offset(74, 126);
    const hoverLift = 150.0;
    final position = Offset.lerp(Offset.zero, markOnPage, t)!;
    final boxLift = hoverLift * t * settle;

    final exitOffset = Offset(0, -exit * 430);

    // At rest the card is bigger than the box is on the page: the camera
    // pulls back as the page comes into view. Measured off the reference.
    final exitScale = (1 + 0.16 * exit) * lerpDouble(2.0, 1.0, t)!;

    // The toast straddles the page's bottom edge. The frame grows by the
    // overlap while the page is tilted and gives it back as the camera rises.
    final hang = 72.0 * (t - rise).clamp(0.0, 1.0);

    return SizedBox(
      height: lerpDouble(268, 356, t)! + rise * 125 + hang,
      width: 620,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: hang,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (t > 0.01)
                  Unclamped(
                    child: Opacity(
                      opacity: Curves.easeOut.transform(t.clamp(0.0, 1.0)),
                      child: Transform(
                        key: cameraKey,
                        alignment: Alignment.center,
                        transform: camera3d,
                        // The sheet is designed at a readable width and scaled
                        // up so the page reads large against the head.
                        child: Transform.scale(
                          scale: 1.18,
                          child: InvoiceSheet(
                            headText: headText,
                            date: date,
                            color: ink,
                            bleed: bleed,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Opacity sits inside the transforms, not outside them: a
                // proxy box rejects pointers beyond its own unscaled bounds
                // before a scale below it could map them back, which left
                // the outer wheel columns unreachable at the resting scale.
                Unclamped(
                  child: Transform.translate(
                    offset: exitOffset,
                    child: Transform.scale(
                      scale: exitScale,
                      child: Opacity(
                        opacity: (1 - (lift - 0.55) / 0.45).clamp(0.0, 1.0),
                        child: StampCube(
                          angle: angle,
                          // Weaker than the page's, or the hover swells the
                          // box by a fifth; the reference barely changes size.
                          perspective: perspective * 0.5,
                          position: position,
                          lift: boxLift,
                          rest: 1 - t,
                          width: Box.width,
                          depth: Box.depth,
                          height: Box.height,
                          face: StampFace(
                            date: date,
                            headText: headText,
                            color: color,
                            background: StampCube.lidTone(1 - t),
                            interactive: interactive,
                            onDateChanged: onDateChanged,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (toast != null) Positioned(bottom: 0, child: toast!),
        ],
      ),
    );
  }
}
