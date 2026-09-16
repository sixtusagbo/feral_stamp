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
      home: const StampPage(),
    );
  }
}
