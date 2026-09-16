import 'package:flutter/material.dart';

import '../invoice.dart';
import '../theme.dart';
import 'date_wheel.dart';

/// The object that holds the wheels *and* does the stamping.
///
/// Flat on the page it reads as a control. Once the camera tilts, [solid] grows
/// the body and the rubber pad beneath it so the same widget becomes a physical
/// block. It is deliberately one widget: swapping in a different one
/// mid-animation is what makes these transitions feel fake.
///
/// It is a box seen from above. The *top face* (the wheels) lies in the same
/// plane as the paper, so it takes the camera's tilt and foreshortens with it,
/// hinged along its bottom edge. The *front face* (the body) is vertical and is
/// drawn square to the viewer. Rotating the whole block turns it into a wedge;
/// rotating none of it leaves a flat card. Only the face tilts.
class StampHead extends StatelessWidget {
  const StampHead({
    super.key,
    required this.date,
    required this.headText,
    required this.color,
    required this.onDateChanged,
    this.interactive = true,
    this.solid = false,
    this.faceTilt,
  });

  final DateTime date;

  /// Caps printed on the head; 'VOID' replaces the label when voiding.
  final String headText;
  final Color color;
  final ValueChanged<DateTime> onDateChanged;

  /// Wheels only scroll while the picker is on screen.
  final bool interactive;

  /// Grows the block into its pressing form: body, rubber pad, contact shadow.
  final bool solid;

  /// The camera's rotation, applied to the top face only. Null means flat.
  final Matrix4? faceTilt;

  static const width = 300.0;
  static const _radius = 30.0;
  static const _bodyHeight = 96.0;
  static const _padHeight = 17.0;
  static const _padInset = 13.0;

  void _emit({int? day, int? month, int? year}) {
    final y = year ?? date.year;
    final m = month ?? date.month;
    final d = (day ?? date.day).clamp(1, daysInMonth(y, m));
    onDateChanged(DateTime(y, m, d));
  }

  @override
  Widget build(BuildContext context) {
    final faceRadius = BorderRadius.vertical(
      top: const Radius.circular(_radius),
      bottom: Radius.circular(solid ? 0 : _radius),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hinged along its bottom edge so it stays attached to the body as it
        // tips back.
        Transform(
          alignment: Alignment.bottomCenter,
          transform: faceTilt ?? Matrix4.identity(),
          child: Container(
            width: width,
            decoration: BoxDecoration(
              borderRadius: faceRadius,
              boxShadow: [
                if (!solid)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 28,
                    spreadRadius: -6,
                    offset: const Offset(0, 12),
                  ),
              ],
            ),
            child: ClipRRect(borderRadius: faceRadius, child: _face()),
          ),
        ),
        if (solid) ...[
          Container(
            width: width,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(_radius + 6),
              ),
              boxShadow: [
                // Contact shadow: tight and dark near the pad, so the block
                // rests on the paper rather than floating over it.
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 28,
                  spreadRadius: -6,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 60,
                  spreadRadius: -4,
                  offset: const Offset(0, 36),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(_radius + 6),
              ),
              child: _body(),
            ),
          ),
          _pad(),
        ],
      ],
    );
  }

  // The lit top of the block, carrying the wheels.
  Widget _face() {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 14, 17, 13),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1F1F4), Color(0xFFF7F7F9)],
        ),
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
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DateWheel(
                values: Wheels.days,
                index: date.day - 1,
                axisLabel: 'DAY',
                width: 62,
                enabled: interactive,
                onChanged: (i) => _emit(day: i + 1),
              ),
              DateWheel(
                values: Wheels.months,
                index: date.month - 1,
                axisLabel: 'MONTH',
                width: 84,
                enabled: interactive,
                onChanged: (i) => _emit(month: i + 1),
              ),
              DateWheel(
                values: Wheels.years,
                index: date.year - 2021,
                axisLabel: 'YEAR',
                width: 84,
                enabled: interactive,
                onChanged: (i) => _emit(year: 2021 + i),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The blank mass of the stamp. A horizontal highlight down the middle with
  /// the sides falling off is what makes it read as round rather than as a
  /// flat panel.
  Widget _body() {
    return Container(
      height: _bodyHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFDCDCE2),
            Color(0xFFF4F4F7),
            Color(0xFFFFFFFF),
            Color(0xFFFDFDFE),
            Color(0xFFE9E9EE),
            Color(0xFFD6D6DD),
          ],
          stops: [0.0, 0.14, 0.38, 0.58, 0.86, 1.0],
        ),
      ),
      // Darkens towards the pad so the body turns under rather than ending.
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0x00000000), Color(0x1A000000)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }

  /// The rubber that meets the paper. Inset from the body's width so the block
  /// appears to wrap over it, and lit along its top edge.
  Widget _pad() {
    return Container(
      width: width - _padInset * 2,
      height: _padHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A3A45), Color(0xFF15151B)],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(3),
          bottom: Radius.circular(11),
        ),
      ),
    );
  }
}
