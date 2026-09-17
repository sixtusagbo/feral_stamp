import 'package:flutter/material.dart';

import '../invoice.dart';
import '../theme.dart';
import 'controls.dart';

/// The confirmation that straddles the page's bottom edge once the stamp has
/// landed: what was printed, and Undo or Done.
class StampToast extends StatelessWidget {
  const StampToast({
    super.key,
    required this.text,
    required this.ink,
    required this.onUndo,
    required this.onDone,
  });

  final String text;
  final Color ink;
  final VoidCallback onUndo;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Tone.cardEdge),
        boxShadow: paperShadow(0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Helvetica Neue',
              fontSize: 16,
              color: Tone.text,
            ),
          ),
          const SizedBox(width: 16),
          PillButton(text: 'Undo', onTap: onUndo),
          const SizedBox(width: 6),
          PillButton(text: 'Done', filled: true, onTap: onDone),
        ],
      ),
    );
  }
}
