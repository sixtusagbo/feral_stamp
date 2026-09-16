import 'package:flutter/material.dart';

import 'src/stamp_page.dart';
import 'src/theme.dart';

void main() => runApp(const FeralStampApp());

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
