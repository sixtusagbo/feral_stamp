import 'package:flutter/material.dart';

import '../invoice.dart';
import '../theme.dart';
import 'date_wheel.dart';

/// The chunky card that holds the wheels. It is the stamp: in the picker phase
/// it reads as a control, and in the press phase the same body tips into 3D and
/// comes down on the paper, so the object never changes identity mid-animation.
class StampHead extends StatelessWidget {
  const StampHead({
    super.key,
    required this.date,
    required this.headText,
    required this.color,
    required this.onDateChanged,
    this.interactive = true,
    this.showUnderside = false,
  });

  final DateTime date;

  /// Caps printed on the head; 'VOID' replaces the label when voiding.
  final String headText;
  final Color color;
  final ValueChanged<DateTime> onDateChanged;

  /// Wheels only scroll while the picker is on screen.
  final bool interactive;

  /// The dark rubber pad, revealed once the head tips towards the paper.
  final bool showUnderside;

  static const width = 268.0;

  void _emit({int? day, int? month, int? year}) {
    final y = year ?? date.year;
    final m = month ?? date.month;
    final d = (day ?? date.day).clamp(1, daysInMonth(y, m));
    onDateChanged(DateTime(y, m, d));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: Tone.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Tone.cardEdge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(headText, style: Type.eyebrow),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DateWheel(
                    values: Wheels.days,
                    index: date.day - 1,
                    axisLabel: 'DAY',
                    width: 58,
                    enabled: interactive,
                    onChanged: (i) => _emit(day: i + 1),
                  ),
                  DateWheel(
                    values: Wheels.months,
                    index: date.month - 1,
                    axisLabel: 'MONTH',
                    width: 76,
                    enabled: interactive,
                    onChanged: (i) => _emit(month: i + 1),
                  ),
                  DateWheel(
                    values: Wheels.years,
                    index: date.year - 2021,
                    axisLabel: 'YEAR',
                    width: 76,
                    enabled: interactive,
                    onChanged: (i) => _emit(year: 2021 + i),
                  ),
                ],
              ),
            ],
          ),
        ),
        // The rubber pad only exists once we are looking at the head in 3D.
        if (showUnderside)
          Container(
            width: width - 26,
            height: 13,
            decoration: const BoxDecoration(
              color: Tone.cardUnder,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(9)),
            ),
          ),
      ],
    );
  }
}
