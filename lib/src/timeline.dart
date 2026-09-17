import 'package:flutter/animation.dart';

/// Where we are in the press. The whole animation is one timeline; this enum
/// just names the regions so the UI can decide what to show.
enum Stage { picking, pressing, stamped }

/// Timeline offsets. The five durations are the reference component's own
/// control panel: camera tilt 0.80s, press 0.15s, lift away 0.42s, camera
/// rise 0.70s (bounce is a shape, not a duration). The two holds are read off
/// its video: the stamp pauses at the top of its hover before dropping, and
/// rests on the paper before lifting. Without them the same numbers feel
/// rushed, which is exactly the note the original author gave.
class Timeline {
  static const tilt = 800;
  static const hoverHold = 150;
  static const press = 150;
  static const contactHold = 200;
  static const lift = 420;
  static const rise = 700;

  static const pressAt = tilt + hoverHold;

  /// The rubber meets the paper: thud, ink, and the start of the rest.
  static const contactAt = pressAt + press;
  static const liftAt = contactAt + contactHold;
  static const riseAt = liftAt + lift;
  static const total = riseAt + rise;

  static Interval span(int start, int len, [Curve c = Curves.linear]) =>
      Interval(start / total, (start + len) / total, curve: c);
}
