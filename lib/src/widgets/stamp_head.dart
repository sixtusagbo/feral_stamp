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

  static const width = 272.0;
  static const _radius = 28.0;

  /// The body's bottom corners. Large, so the silhouette turns under rather
  /// than ending in a shoulder.
  static const _heel = 44.0;
  static const _bodyHeight = 64.0;

  /// How far the rubber pad shows beneath the body.
  static const _padReveal = 11.0;
  static const _padInset = 16.0;

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

    final face = Transform(
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
    );

    if (!solid) return face;

    // The pad sits under the body and peeks out beneath its curved heel, so
    // the block reads as a rounded mass resting on a thinner rubber base.
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Positioned(bottom: 0, child: _pad()),
        Padding(
          padding: const EdgeInsets.only(bottom: _padReveal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [face, _body()],
          ),
        ),
      ],
    );
  }

  // The lit top of the block, carrying the wheels.
  Widget _face() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4F4F7), Color(0xFFFAFAFC)],
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
                width: 54,
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
    );
  }

  /// The blank mass of the stamp. A horizontal highlight down the middle with
  /// the sides falling off is what makes it read as round rather than as a
  /// flat panel, and the heel darkens so the body visibly turns under.
  Widget _body() {
    const radius = BorderRadius.vertical(bottom: Radius.circular(_heel));
    return Container(
      width: width,
      height: _bodyHeight,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          // Contact shadow: tight and dark so the block rests on the paper.
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 26,
            spreadRadius: -8,
            offset: const Offset(0, 22),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 60,
            spreadRadius: -4,
            offset: const Offset(0, 40),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD9D9E0),
                Color(0xFFF3F3F6),
                Color(0xFFFFFFFF),
                Color(0xFFFDFDFE),
                Color(0xFFE8E8ED),
                Color(0xFFD3D3DB),
              ],
              stops: [0.0, 0.14, 0.40, 0.60, 0.86, 1.0],
            ),
          ),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0x22000000),
                ],
                stops: [0.0, 0.62, 1.0],
              ),
            ),
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  /// The rubber that meets the paper. Narrower than the body and sharing its
  /// heel radius, so what shows is a thin dark band following the curve.
  Widget _pad() {
    return Container(
      width: width - _padInset * 2,
      height: _bodyHeight * 0.6 + _padReveal,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B3B46), Color(0xFF1B1B22), Color(0xFF0E0E13)],
          stops: [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(_heel - 6)),
      ),
    );
  }
}
