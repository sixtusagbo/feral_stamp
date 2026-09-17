import 'package:flutter/material.dart';

import '../invoice.dart';
import '../theme.dart';
import 'controls.dart';

/// Everything under the resting card: the date readout, the label tray, the
/// ink swatches, the button and its footnote.
class PickerControls extends StatelessWidget {
  const PickerControls({
    super.key,
    required this.date,
    required this.label,
    required this.color,
    required this.onLabel,
    required this.onColor,
    required this.onStamp,
    required this.onVoid,
  });

  final DateTime date;
  final StampLabel label;
  final Color color;
  final ValueChanged<StampLabel> onLabel;
  final ValueChanged<Color> onColor;
  final VoidCallback onStamp;

  /// Holding the button stamps VOID instead of the label.
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          date.longLine,
          style: Type.body.copyWith(
            color: Tone.text,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 24),
        // Wraps so the tray and the swatches stack on a narrow screen instead
        // of running off the edge.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 12,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Tone.chipTray,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final l in StampLabel.values)
                    LabelChip(
                      text: l.chip,
                      selected: l == label,
                      onTap: () => onLabel(l),
                    ),
                ],
              ),
            ),
            Container(width: 1, height: 30, color: Tone.cardEdge),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in Tone.swatches) ...[
                  InkSwatch(
                    color: c,
                    selected: c == color,
                    onTap: () => onColor(c),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 22),
        GestureDetector(
          onTap: onStamp,
          onLongPress: onVoid,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 15),
            decoration: BoxDecoration(
              color: Tone.text,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label.action,
              style: const TextStyle(
                fontFamily: 'Helvetica Neue',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'or press Enter · hold to void',
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 12,
            color: Tone.muted,
          ),
        ),
      ],
    );
  }
}
