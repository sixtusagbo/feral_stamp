import 'package:flutter/material.dart';

import '../invoice.dart';
import '../theme.dart';
import 'date_wheel.dart';

/// What is printed on the stamp's lid: the label, the ink dot, and the three
/// date wheels. It is laid out at the lid's own size and travels with it, so
/// it foreshortens under the camera along with the lid.
class StampFace extends StatelessWidget {
  const StampFace({
    super.key,
    required this.date,
    required this.headText,
    required this.color,
    required this.background,
    required this.onDateChanged,
    this.interactive = true,
  });

  final DateTime date;

  /// Caps printed on the lid; 'VOID' replaces the label when voiding.
  final String headText;
  final Color color;

  /// The lid's tone, so the wheels can fade into it at their ends.
  final Color background;
  final ValueChanged<DateTime> onDateChanged;

  /// Wheels only scroll while the picker is on screen.
  final bool interactive;

  static const _rowHeight = 22.0;
  static const _fontSize = 13.5;

  void _emit({int? day, int? month, int? year}) {
    final y = year ?? date.year;
    final m = month ?? date.month;
    final d = (day ?? date.day).clamp(1, daysInMonth(y, m));
    onDateChanged(DateTime(y, m, d));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                headText,
                style: Type.eyebrow.copyWith(fontSize: 7.5, letterSpacing: 1.6),
              ),
              const Spacer(),
              Container(
                width: 6.5,
                height: 6.5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DateWheel(
                values: Wheels.days,
                index: date.day - 1,
                axisLabel: 'DAY',
                width: 54,
                rowHeight: _rowHeight,
                fontSize: _fontSize,
                fade: background,
                enabled: interactive,
                onChanged: (i) => _emit(day: i + 1),
              ),
              DateWheel(
                values: Wheels.months,
                index: date.month - 1,
                axisLabel: 'MONTH',
                width: 66,
                rowHeight: _rowHeight,
                fontSize: _fontSize,
                fade: background,
                enabled: interactive,
                onChanged: (i) => _emit(month: i + 1),
              ),
              DateWheel(
                values: Wheels.years,
                index: date.year - 2021,
                axisLabel: 'YEAR',
                width: 66,
                rowHeight: _rowHeight,
                fontSize: _fontSize,
                fade: background,
                enabled: interactive,
                onChanged: (i) => _emit(year: 2021 + i),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
