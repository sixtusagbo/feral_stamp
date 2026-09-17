import 'package:flutter/material.dart';

import '../theme.dart';

/// The small controls under the picker: a label chip in its tray, an ink
/// swatch, and the pill buttons on the toast and the finished state.
class LabelChip extends StatelessWidget {
  const LabelChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Tone.text : Tone.muted,
          ),
        ),
      ),
    );
  }
}

class InkSwatch extends StatelessWidget {
  const InkSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            width: 23,
            height: 23,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.text,
    required this.onTap,
    this.filled = false,
    this.large = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool filled;

  /// The finished state's actions are the size of the main button.
  final bool large;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: large
            ? const EdgeInsets.symmetric(horizontal: 34, vertical: 15)
            : const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? Tone.text : (large ? Tone.chipTray : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Tone.cardEdge),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: large ? 15 : 14,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : Tone.text,
          ),
        ),
      ),
    );
  }
}
