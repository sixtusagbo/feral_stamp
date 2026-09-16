import 'package:flutter/material.dart';

import '../theme.dart';

/// The red impression left on the paper: a double-ruled rounded box with the
/// label above the date, rotated a touch so it reads as hand-pressed.
///
/// [bleed] drives the ink: 0 is nothing, 1 is a full, settled press. The mark
/// lands slightly oversized and contracts, the way rubber rebounds off paper.
class StampMark extends StatelessWidget {
  const StampMark({
    super.key,
    required this.label,
    required this.date,
    required this.color,
    this.bleed = 1,
    this.rotation = -0.035,
  });

  final String label;
  final String date;
  final Color color;
  final double bleed;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    if (bleed <= 0) return const SizedBox.shrink();

    final settle = Curves.easeOutCubic.transform(bleed.clamp(0.0, 1.0));
    // Overshoot the scale early, then relax into place.
    final scale = 1.06 - 0.06 * settle;

    return Opacity(
      opacity: settle,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          child: CustomPaint(
            painter: _MarkPainter(color: color, bleed: settle),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 9, 18, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.color, required this.bleed});

  final Color color;
  final double bleed;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(7),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(3.5, 3.5, size.width - 7, size.height - 7),
      const Radius.circular(4.5),
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = color.withValues(alpha: 0.92 * bleed)
      ..strokeWidth = 2.2;

    canvas.drawRRect(outer, stroke);
    canvas.drawRRect(inner, stroke..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.bleed != bleed || old.color != color;
}
