import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The stamp as a real box under one camera.
///
/// Three quads share a single perspective and rotation. The camera tips the
/// page back by [angle]; the box sits on the page, so its top face takes the
/// same tilt and its front face, vertical in the world, ends up rotated
/// `pi/2 - angle` and foreshortened too. A shadow quad lies flat on the page
/// beneath it. Because all three come off the same matrix they stay
/// consistent at any angle, which is what earlier attempts (a tilted card, a
/// screen-space slab) never managed.
///
/// Local frame: origin at the base centre on the page, X right, Y down the
/// page towards the viewer, Z up off the page. Flutter's Z points into the
/// screen, so "up" is negative Z here.
class StampCube extends StatelessWidget {
  const StampCube({
    super.key,
    required this.angle,
    this.perspective = 0.0016,
    this.width = 240,
    this.depth = 112,
    this.height = 118,
    this.position = Offset.zero,
    this.lift = 0,
    this.face,
  });

  /// Camera tilt in radians. 0 is flat-on.
  final double angle;
  final double perspective;

  final double width;

  /// Extent along the page (the top face's height when seen flat).
  final double depth;

  /// How tall the box stands off the page.
  final double height;

  /// Where the base centre sits on the page, in the page's coordinates.
  final Offset position;

  /// How far the base is raised off the page along its normal.
  final double lift;

  /// Content drawn on the top face. Null leaves it blank.
  final Widget? face;

  static const _topRadius = 28.0;
  static const _heelRadius = 22.0;
  static const _edge = 13.0;

  Matrix4 _camera() => Matrix4.identity()
    ..setEntry(3, 2, perspective)
    ..rotateX(-angle)
    ..translateByDouble(position.dx, position.dy, -lift, 1);

  @override
  Widget build(BuildContext context) {
    // Every quad is centred on the same point, so one alignment works for all.
    return SizedBox(
      width: width,
      height: depth,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: _camera(),
            child: _shadow(),
          ),
          Transform(
            alignment: Alignment.center,
            transform: _camera()
              ..translateByDouble(0, depth / 2, -height / 2, 1)
              ..rotateX(math.pi / 2),
            child: _front(),
          ),
          Transform(
            alignment: Alignment.center,
            transform: _camera()..translateByDouble(0, 0, -height, 1),
            child: _top(),
          ),
        ],
      ),
    );
  }

  /// The lit top. Slightly darker at the back edge, and it carries the
  /// rounded corners that read as the box's softened top edges.
  Widget _top() {
    return Container(
      width: width,
      height: depth,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_topRadius)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE6E6EB), Color(0xFFF2F2F5), Color(0xFFF7F7F9)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: face,
    );
  }

  /// The front face, with a highlight down its middle so the vertical edges
  /// read as rounded, a crease along the top where it meets the lid, and the
  /// rubber as a dark strip along the base: the cube's bottom edge.
  Widget _front() {
    const radius = BorderRadius.vertical(bottom: Radius.circular(_heelRadius));
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFD6D6DD),
                    Color(0xFFF0F0F4),
                    Color(0xFFFFFFFF),
                    Color(0xFFFCFCFD),
                    Color(0xFFEBEBF0),
                    Color(0xFFD2D2DA),
                  ],
                  stops: [0.0, 0.14, 0.40, 0.60, 0.86, 1.0],
                ),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66FFFFFF),
                      Color(0x00FFFFFF),
                      Color(0x00000000),
                      Color(0x16000000),
                    ],
                    stops: [0.0, 0.06, 0.70, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 2,
            right: 2,
            bottom: 0,
            height: _edge,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(_heelRadius - 2),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF34343E), Color(0xFF14141A)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lies flat on the page. Softens and fades as the box lifts, which is the
  /// cue that tells you how high it is.
  Widget _shadow() {
    final t = (lift / 160).clamp(0.0, 1.0);
    final spread = 1 + t * 0.5;
    return Container(
      width: (width + 70) * spread,
      height: (depth + 60) * spread,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(60),
        gradient: RadialGradient(
          colors: [
            Colors.black.withValues(alpha: 0.34 * (1 - t * 0.7)),
            Colors.black.withValues(alpha: 0.10 * (1 - t * 0.7)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
