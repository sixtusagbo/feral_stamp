import 'package:flutter/material.dart';

/// Hands its child unbounded constraints so it keeps its natural size inside a
/// smaller animated frame.
class Unclamped extends StatelessWidget {
  const Unclamped({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => OverflowBox(
    minWidth: 0,
    minHeight: 0,
    maxWidth: double.infinity,
    maxHeight: double.infinity,
    child: child,
  );
}
