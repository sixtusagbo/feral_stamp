import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'src/stamp_page.dart';
import 'src/theme.dart';

void main() {
  // Debug affordance: ?slow=8 runs the whole timeline 8x slower so the press
  // can be inspected frame by frame. Ignored when the param is absent.
  final slow = double.tryParse(Uri.base.queryParameters['slow'] ?? '');
  if (slow != null && slow > 0) timeDilation = slow;
  runApp(const FeralStampApp());
}

class FeralStampApp extends StatelessWidget {
  const FeralStampApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stamp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Tone.page,
        colorScheme: ColorScheme.fromSeed(seedColor: Tone.stamp),
      ),
      // Flutter leaves mouse and trackpad out of dragDevices by default, so
      // on web and desktop a cursor cannot roll the wheels at all. This is a
      // component you drag, so they have to be in.
      scrollBehavior: const _DragWithAnything(),
      home: const StampPage(),
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
