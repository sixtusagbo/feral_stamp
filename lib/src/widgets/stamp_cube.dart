import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The stamp as a real object under one camera.
///
/// It is an extruded rounded rectangle: the lid's outline swept from the page
/// up to the lid. The side surface is painted as that sweep, a stack of thin
/// slices of the same rounded rect at increasing height, each pushed through
/// the camera, so its corners are quarter-cylinders and its outline hugs the
/// lid's at every angle. Seen nearly flat it collapses into a thin band that
/// follows the lid's curve; seen from above it is a tall wall with rounded
/// corners. Drawing the wall as a flat slab behind the lid gets neither: the
/// corners come out as square ears and the junction reads as a shelf.
///
/// The rubber is simply the bottom slices, inset and dark. The lid is a
/// widget so it can carry the wheels. A shadow lies flat on the page beneath.
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

  /// How tall the object stands off the page, pad included.
  final double height;

  /// Where the base centre sits on the page, in the page's coordinates.
  final Offset position;

  /// How far the base is raised off the page along its normal.
  final double lift;

  /// 1 while the object is still the flat picker card, 0 once it is on the
  /// page. Drives the shadow (a soft lift at rest, contact on the page) and
  /// the lid's tint.
  final double rest;

  /// Content drawn on the lid. Null leaves it blank.
  final Widget? face;

  static const radius = 30.0;
  static const padHeight = 13.0;

  /// The lid's mid tone at a given [rest], for anything that has to blend
  /// into it.
  static Color lidTone(double rest) =>
      Color.lerp(const Color(0xFFF1F1F4), const Color(0xFFFBFBFC), rest)!;

  Matrix4 _camera() => Matrix4.identity()
    ..setEntry(3, 2, perspective)
    ..rotateX(-angle)
    ..translateByDouble(position.dx, position.dy, -lift, 1);

  @override
  Widget build(BuildContext context) {
    // Every layer is centred on the same point, so one alignment works for all.
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
          if (angle > 0.005)
            CustomPaint(
              size: Size(width, depth),
              painter: _SidePainter(
                camera: _camera(),
                height: height,
                padHeight: padHeight,
                radius: radius,
              ),
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
  /// A shade greyer than the lit wall, and lighter again at rest where there
  /// is nothing for it to be in the shade of.
  Widget _lid() {
    return Container(
      width: width,
      height: depth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFFEAEAEE), const Color(0xFFF9F9FA), rest)!,
            lidTone(rest),
            Color.lerp(const Color(0xFFF5F5F7), const Color(0xFFFDFDFD), rest)!,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: face,
    );
  }

  /// Lies flat on the page, nudged towards the viewer. Soft and light: the
  /// reference glows off the page rather than sitting in a pool of shade. At
  /// rest it is the card's lift; on the page it draws in a little, then
  /// spreads and thins again as the object is raised.
  Widget _shadow() {
    final t = (lift / 120).clamp(0.0, 1.0);
    final ground = 1 - rest;
    final strength = (1 - t * 0.6) * (0.55 + 0.45 * ground);
    return Container(
      width: width,
      height: depth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
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

/// Paints the side surface as a sweep of the lid's rounded rect from the page
/// (h = 0) up to just under the lid, bottom slice first so each one covers the
/// last and only the front band of every slice survives. Shading is by height:
/// dark rubber at the base, a lit wall above it that falls off towards the
/// heel, and a faint horizontal vignette so the wall reads as having some
/// roundness across it.
class _SidePainter extends CustomPainter {
  const _SidePainter({
    required this.camera,
    required this.height,
    required this.padHeight,
    required this.radius,
  });

  final Matrix4 camera;
  final double height;
  final double padHeight;
  final double radius;

  static const _step = 1.25;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final slices = (height / _step).ceil();

    for (var i = 0; i <= slices; i++) {
      final h = math.min(i * _step, height);
      final isPad = h < padHeight;

      // The pad is a little narrower than the wall, and the wall's base is
      // filleted into it over a few slices so the heel turns under.
      var inset = 0.0;
      if (isPad) {
        inset = 6.0;
      } else {
        const fillet = 9.0;
        final up = h - padHeight;
        if (up < fillet) {
          final k = 1 - up / fillet;
          inset = fillet * (1 - math.sqrt(1 - k * k));
        }
      }

      final rect = Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      );
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(math.max(radius - inset, 4)),
      );

      final tone = _tone(h);
      final paint = Paint()
        ..isAntiAlias = true
        ..shader = LinearGradient(
          colors: [
            Color.lerp(tone, Colors.black, 0.10)!,
            tone,
            tone,
            Color.lerp(tone, Colors.black, 0.10)!,
          ],
          stops: const [0.0, 0.16, 0.84, 1.0],
        ).createShader(rect);

      final m = camera.clone()..translateByDouble(0, 0, -h, 1);

      canvas
        ..save()
        ..translate(centre.dx, centre.dy)
        ..transform(m.storage)
        ..translate(-centre.dx, -centre.dy)
        ..drawRRect(rrect, paint)
        ..restore();
    }
  }

  Color _tone(double h) {
    if (h < padHeight) {
      final k = h / padHeight;
      return Color.lerp(const Color(0xFF111116), const Color(0xFF34343E), k)!;
    }
    final k = ((h - padHeight) / (height - padHeight)).clamp(0.0, 1.0);
    // Heel to lid: light grey, up to white, with a shade taken off right
    // under the lid's lip.
    if (k < 0.55) {
      return Color.lerp(
        const Color(0xFFE9E9EE),
        const Color(0xFFFFFFFF),
        k / 0.55,
      )!;
    }
    if (k < 0.94) return const Color(0xFFFFFFFF);
    return Color.lerp(
      const Color(0xFFFFFFFF),
      const Color(0xFFE6E6EB),
      (k - 0.94) / 0.06,
    )!;
  }

  @override
  bool shouldRepaint(_SidePainter old) =>
      old.camera != camera ||
      old.height != height ||
      old.padHeight != padHeight ||
      old.radius != radius;
}
