import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'src/stamp_page.dart';
import 'src/stamp_sound.dart';
import 'src/theme.dart';

void main() {
  // Debug affordance: ?slow=8 runs the whole timeline 8x slower so the press
  // can be inspected frame by frame. Ignored when the param is absent.
  final slow = double.tryParse(Uri.base.queryParameters['slow'] ?? '');
  if (slow != null && slow > 0) timeDilation = slow;
  runApp(const FeralStampApp());
}

class FeralStampApp extends StatelessWidget {
  const FeralStampApp({super.key, this.sound});

  /// Passed through to the page; tests hand in [StampSound.silent].
  final StampSound? sound;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stamp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Tone.page,
        colorScheme: ColorScheme.fromSeed(seedColor: Tone.stamp),
      ),
      // Flutter leaves the mouse out of dragDevices by default (touch, stylus
      // and trackpad are in), so on web and desktop a mouse cannot drag the
      // wheels at all. This is a component you drag, so it has to be in.
      scrollBehavior: const _DragWithAnything(),
      home: StampPage(sound: sound),
    );
  }
}

class _DragWithAnything extends MaterialScrollBehavior {
  const _DragWithAnything();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}
