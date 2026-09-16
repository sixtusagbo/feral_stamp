import 'dart:math';

import 'package:flutter/material.dart';

/// The red impression left on the paper.
///
/// A rubber stamp never prints cleanly: the ink breaks up along the border and
/// the rules are uneven. The border is drawn as a path with deterministic gaps
/// bitten out of it, so it reads as pressed rather than drawn.
class StampMark extends StatelessWidget {
  const StampMark({
    super.key,
    required this.label,
    required this.date,
    required this.color,
    this.bleed = 1,
    this.rotation = -0.055,
  });

  final String label;
  final String date;
  final Color color;

  /// 0 is no ink, 1 is a settled press.
  final double bleed;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    if (bleed <= 0) return const SizedBox.shrink();

    final settle = Curves.easeOutCubic.transform(bleed.clamp(0.0, 1.0));
    // Land slightly oversized, then contract as the rubber rebounds.
    final scale = 1.09 - 0.09 * settle;

    return Opacity(
      opacity: settle,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          child: CustomPaint(
            painter: _MarkPainter(color: color, bleed: settle),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 13, 26, 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: color.withValues(alpha: 0.92),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: color,
                      height: 1,
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

  /// Fixed seed: the erosion must be identical on every repaint, or the stamp
  /// crawls while the ink fades in.
  static const _seed = 7;

  @override
  void paint(Canvas canvas, Size size) {
    _eroded(
      canvas,
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      width: 3.4,
      gaps: 9,
      seed: _seed,
    );
    _eroded(
      canvas,
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5.5, 5.5, size.width - 11, size.height - 11),
        const Radius.circular(5),
      ),
      width: 1.4,
      gaps: 7,
      seed: _seed + 31,
    );
  }

  /// Traces the rounded rect but skips short stretches, the way ink fails to
  /// transfer where the rubber does not quite meet the paper.
  void _eroded(
    Canvas canvas,
    RRect rrect, {
    required double width,
    required int gaps,
    required int seed,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.93 * bleed)
      ..strokeWidth = width;

    final path = Path()..addRRect(rrect);
    final rng = Random(seed);

    for (final metric in path.computeMetrics()) {
      final total = metric.length;
      // Pick gap positions up front so they stay sorted and non-overlapping.
      final cuts = List.generate(gaps, (_) => rng.nextDouble() * total)..sort();

      var cursor = 0.0;
      for (final cut in cuts) {
        final len = 1.6 + rng.nextDouble() * 3.4;
        if (cut <= cursor) continue;
        canvas.drawPath(metric.extractPath(cursor, cut), paint);
        cursor = cut + len;
      }
      if (cursor < total) {
        canvas.drawPath(metric.extractPath(cursor, total), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.bleed != bleed || old.color != color;
}
