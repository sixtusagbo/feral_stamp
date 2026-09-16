import 'package:flutter/material.dart';

import '../invoice.dart';
import '../theme.dart';
import 'date_wheel.dart';

/// The object that holds the wheels *and* does the stamping.
///
/// Flat on the page it reads as a control. Once the camera tilts, [solid] grows
/// the body and the dark rubber pad beneath it so the same widget becomes a
/// physical block. It is deliberately one widget: swapping in a different one
/// mid-animation is what makes these transitions feel fake.
class StampHead extends StatelessWidget {
  const StampHead({
    super.key,
    required this.date,
    required this.headText,
    required this.color,
    required this.onDateChanged,
    this.interactive = true,
    this.solid = false,
  });

  final DateTime date;

  /// Caps printed on the head; 'VOID' replaces the label when voiding.
  final String headText;
  final Color color;
  final ValueChanged<DateTime> onDateChanged;

  /// Wheels only scroll while the picker is on screen.
  final bool interactive;

  /// Grows the block into 3D: body, rubber pad, contact shadow.
  final bool solid;

  static const width = 330.0;
  static const _radius = 34.0;
  static const _bodyHeight = 74.0;
  static const _padHeight = 20.0;

  void _emit({int? day, int? month, int? year}) {
    final y = year ?? date.year;
    final m = month ?? date.month;
    final d = (day ?? date.day).clamp(1, daysInMonth(y, m));
    onDateChanged(DateTime(y, m, d));
  }

  @override
  Widget build(BuildContext context) {
    final topRadius = BorderRadius.vertical(
      top: const Radius.circular(_radius),
      bottom: Radius.circular(solid ? 0 : _radius),
    );

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: solid ? 0.26 : 0.08),
            blurRadius: solid ? 44 : 26,
            spreadRadius: solid ? -4 : -2,
            offset: Offset(0, solid ? 26 : 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- top face: the wheels
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              color: Tone.card,
              borderRadius: topRadius,
              border: Border.all(color: Tone.cardEdge),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(headText, style: Type.eyebrow),
                    const Spacer(),
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DateWheel(
                      values: Wheels.days,
                      index: date.day - 1,
                      axisLabel: 'DAY',
                      width: 68,
                      enabled: interactive,
                      onChanged: (i) => _emit(day: i + 1),
                    ),
                    DateWheel(
                      values: Wheels.months,
                      index: date.month - 1,
                      axisLabel: 'MONTH',
                      width: 92,
                      enabled: interactive,
                      onChanged: (i) => _emit(month: i + 1),
                    ),
                    DateWheel(
                      values: Wheels.years,
                      index: date.year - 2021,
                      axisLabel: 'YEAR',
                      width: 92,
                      enabled: interactive,
                      onChanged: (i) => _emit(year: 2021 + i),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---- body: the blank mass of the stamp, only real in 3D
          if (solid) ...[
            Container(
              height: _bodyHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Tone.card, Color(0xFFEDEDF1)],
                ),
                border: Border(
                  left: BorderSide(color: Tone.cardEdge),
                  right: BorderSide(color: Tone.cardEdge),
                ),
              ),
              // Side vignettes round the body off so it reads as a cylinder
              // rather than a flat rectangle.
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x14000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x10000000),
                    ],
                    stops: [0.0, 0.16, 0.84, 1.0],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),
            // ---- the rubber pad that meets the paper
            Container(
              height: _padHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A2A33), Tone.cardUnder],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(_radius * 0.55),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
