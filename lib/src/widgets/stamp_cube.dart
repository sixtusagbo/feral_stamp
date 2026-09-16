import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The stamp as a real box under one camera.
///
/// Four quads share a single perspective and rotation. The camera tips the
/// page back by [angle]; the box sits on the page, so its lid takes the same
/// tilt, and its walls, vertical in the world, end up rotated `pi/2 - angle`
/// and foreshortened too. A shadow lies flat on the page beneath it.
///
/// It is a rounded prism, and the reference draws it the way you would in
/// CSS: the lid is a rounded rectangle on *every* corner at *every* angle,
/// and the body is a full-width slab behind it that reaches up past the lid's
/// front edge by one corner radius. The lid covers that overlap everywhere
/// except at its rounded corners, so the body shows through the cutouts and
/// reads as the curved side surface wrapping round. The rubber pad does the
/// same under the body's rounded heel. Squaring the lid's bottom corners into
/// the wall gives a different, boxier object.
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
    this.rest = 0,
    this.face,
  });

  /// Camera tilt in radians. 0 is flat-on.
  final double angle;
  final double perspective;

  final double width;

  /// Extent along the page (the lid's height when seen flat).
  final double depth;

  /// How tall the box stands off the page, pad included.
  final double height;

  /// Where the base centre sits on the page, in the page's coordinates.
  final Offset position;

  /// How far the base is raised off the page along its normal.
  final double lift;

  /// 1 while the box is still the flat picker card, 0 once it is on the page.
  /// Drives the shadow (a soft lift at rest, contact on the page), the lid's
  /// tint, and whether the walls exist at all: edge-on at rest they would
  /// draw as a hairline along the card's bottom edge.
  final double rest;

  /// Content drawn on the lid. Null leaves it blank.
  final Widget? face;

  static const _lidRadius = 30.0;
  static const _heelRadius = 30.0;

  /// The rubber: its own slab under the body, inset and rounded.
  static const _padHeight = 14.0;
  static const _padInset = 7.0;
  static const _padRadius = 24.0;

  /// How far a lower slab reaches up behind the one above it, so it shows
  /// through that slab's rounded corners.
  static const _overlap = 16.0;

  Matrix4 _camera() => Matrix4.identity()
    ..setEntry(3, 2, perspective)
    ..rotateX(-angle)
    ..translateByDouble(position.dx, position.dy, -lift, 1);

  /// A vertical quad in the front plane spanning [from]..[to] off the page.
  Matrix4 _wall(double from, double to) => _camera()
    ..translateByDouble(0, depth / 2, -(from + to) / 2, 1)
    ..rotateX(math.pi / 2);

  @override
  Widget build(BuildContext context) {
    final walls = rest < 0.98;
    final bodyFrom = _padHeight;
    final bodyTo = height + _lidRadius;

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
            transform: _camera()..translateByDouble(4, 12, 0, 1),
            child: _shadow(),
          ),
          if (walls)
            Transform(
              alignment: Alignment.center,
              transform: _wall(0, _padHeight + _overlap),
              child: _pad(_padHeight + _overlap),
            ),
          if (walls)
            Transform(
              alignment: Alignment.center,
              transform: _wall(bodyFrom, bodyTo),
              child: _body(bodyTo - bodyFrom),
            ),
          Transform(
            alignment: Alignment.center,
            transform: _camera()..translateByDouble(0, 0, -height, 1),
            child: _lid(),
          ),
        ],
      ),
    );
  }

  /// The lid: a rounded rectangle on every corner, whatever the camera does.
  /// A shade greyer than the lit body, and lighter again at rest where there
  /// is nothing for it to be in the shade of.
  Widget _lid() {
    return Container(
      width: width,
      height: depth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_lidRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFFEAEAEE), const Color(0xFFF4F4F6), rest)!,
            Color.lerp(const Color(0xFFF1F1F4), const Color(0xFFFAFAFB), rest)!,
            Color.lerp(const Color(0xFFF5F5F7), const Color(0xFFFDFDFD), rest)!,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: face,
    );
  }

  /// The body: full width, lit brightest just under the lid and falling off
  /// towards the heel, with a faint vignette at the sides so the slab reads as
  /// having some roundness across it. Its bottom corners round on the heel
  /// radius; its top is square and hidden behind the lid.
  Widget _body(double h) {
    const radius = BorderRadius.vertical(bottom: Radius.circular(_heelRadius));
    return Container(
      width: width,
      height: h,
      decoration: const BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFF7F7F9),
            Color(0xFFEDEDF1),
          ],
          stops: [0.0, 0.30, 0.72, 1.0],
        ),
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            colors: [
              Color(0x16000000),
              Color(0x00000000),
              Color(0x00000000),
              Color(0x14000000),
            ],
            stops: [0.0, 0.12, 0.88, 1.0],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }

  /// The rubber: a dark slab, narrower than the body, showing beneath the
  /// body's rounded heel and through its corner cutouts.
  Widget _pad(double h) {
    return Container(
      width: width - _padInset * 2,
      height: h,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(_padRadius),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C2C35), Color(0xFF1B1B22), Color(0xFF111116)],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
    );
  }

  /// Lies flat on the page, nudged towards the viewer. Soft and light: the
  /// reference glows off the page rather than sitting in a pool of shade. At
  /// rest it is the card's lift; on the page it draws in a little, then
  /// spreads and thins again as the box is raised.
  Widget _shadow() {
    final t = (lift / 120).clamp(0.0, 1.0);
    final ground = 1 - rest;
    final strength = (1 - t * 0.6) * (0.55 + 0.45 * ground);
    return Container(
      width: width,
      height: depth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_heelRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13 * strength),
            blurRadius: 40 + t * 30 + rest * 20,
            spreadRadius: 10 + t * 14 - rest * 6,
            offset: Offset(0, 16 * rest + 6 * ground),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07 * strength),
            blurRadius: 90 + t * 40,
            spreadRadius: 24,
            offset: Offset(0, 22 * rest + 10 * ground),
          ),
        ],
      ),
    );
  }
}
