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
/// It is a cube seen from above and in front. The *top face* (the wheels)
/// tips back and foreshortens, hinged along the edge it shares with the front.
/// The *front face* (the body) is vertical, drawn square to the viewer, and
/// tall enough to read as a solid. Rotating the whole block turns it into a
/// wedge; rotating none of it leaves a flat card. Only the face tilts.
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

  /// The body's bottom corners. Modest: the reference is a cube with softened
  /// edges, and a large radius here turns it into a dish.
  static const _heel = 22.0;

  /// Tall. The front face of the cube is about as deep as the top face is
  /// wide-to-height, which is most of what makes it read as a solid.
  static const _bodyHeight = 94.0;

  /// How far the rubber shows beneath the body: a thin strip, the cube's
  /// bottom edge, not a base it sits on.
  static const _padReveal = 10.0;
  static const _padInset = 2.0;

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

  /// The front face of the cube. A vertical gradient does most of the work:
  /// a shaded crease along the top where it meets the tipped-back face, a lit
  /// middle, and a gentle fall-off towards the base. A faint side vignette
  /// keeps it from reading as a flat panel.
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
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 20),
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
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE3E3E8),
                Color(0xFFF6F6F8),
                Color(0xFFFFFFFF),
                Color(0xFFFBFBFC),
                Color(0xFFEDEDF1),
              ],
              stops: [0.0, 0.10, 0.42, 0.78, 1.0],
            ),
          ),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x14000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0x12000000),
                ],
                stops: [0.0, 0.12, 0.88, 1.0],
              ),
            ),
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  /// The rubber that meets the paper: a thin dark strip the width of the body,
  /// sharing its corner radius, so it reads as the cube's bottom edge.
  Widget _pad() {
    return Container(
      width: width - _padInset * 2,
      height: _bodyHeight * 0.5 + _padReveal,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E2E37), Color(0xFF17171D), Color(0xFF0C0C10)],
          stops: [0.0, 0.75, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(_heel - 1)),
      ),
    );
  }
}
