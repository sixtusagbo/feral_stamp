import 'package:flutter/animation.dart';

/// Where we are in the press. The whole animation is one timeline; this enum
/// just names the regions so the UI can decide what to show.
enum Stage { picking, pressing, stamped }

/// Timeline offsets, derived from the reference component's own control panel:
/// camera tilt 0.80s, press 0.15s, lift away 0.42s, camera rise 0.70s.
class Timeline {
  static const tilt = 800;
  static const press = 150;
  static const lift = 420;
  static const rise = 700;

  static const pressAt = tilt;
  static const liftAt = pressAt + press;
  static const riseAt = liftAt + lift;
  static const total = riseAt + rise;

  static Interval span(int start, int len, [Curve c = Curves.linear]) =>
      Interval(start / total, (start + len) / total, curve: c);
}
