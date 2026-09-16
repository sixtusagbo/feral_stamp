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

  /// Big: the front wall turns under into the base rather than meeting it at
  /// a corner, which is most of what makes the block read as a solid.
  static const _heelRadius = 40.0;
  static const _edge = 12.0;
  static const _edgeInset = 5.0;

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
            transform: _camera()..translateByDouble(6, 14, 0, 1),
            child: _shadow(),
          ),
          Transform(
            alignment: Alignment.center,
            transform: _camera()..translateByDouble(0, 4, 0, 1),
            child: _contact(),
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
          colors: [Color(0xFFEBEBEF), Color(0xFFF2F2F5), Color(0xFFF6F6F8)],
          stops: [0.0, 0.6, 1.0],
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
                    Color(0xFFCFCFD7),
                    Color(0xFFEDEDF2),
                    Color(0xFFFFFFFF),
                    Color(0xFFFDFDFE),
                    Color(0xFFE9E9EE),
                    Color(0xFFCBCBD4),
                  ],
                  stops: [0.0, 0.16, 0.42, 0.58, 0.84, 1.0],
                ),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x24000000),
                      Color(0x06000000),
                      Color(0x00000000),
                      Color(0x14000000),
                    ],
                    stops: [0.0, 0.16, 0.66, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: _edgeInset,
            right: _edgeInset,
            bottom: 0,
            height: _edge,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(_heelRadius - _edgeInset),
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

  /// Lies flat on the page, offset a little towards the viewer. A blurred
  /// shadow on the footprint rather than a gradient fill: a radial gradient
  /// reaches transparent at half the shortest side, which is inside the box's
  /// own outline, so nothing of it ever showed.
  Widget _shadow() {
    final t = (lift / 120).clamp(0.0, 1.0);
    final strength = 1 - t * 0.7;
    return Container(
      width: width,
      height: depth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_heelRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26 * strength),
            blurRadius: 34 + t * 30,
            spreadRadius: 14 + t * 16,
          ),
        ],
      ),
    );
  }

  /// A tight dark shadow hugging the base, gone almost as soon as the box
  /// leaves the page: the cue for the moment of contact.
  Widget _contact() {
    final t = (lift / 40).clamp(0.0, 1.0);
    return Container(
      width: width,
      height: depth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_heelRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34 * (1 - t)),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}
