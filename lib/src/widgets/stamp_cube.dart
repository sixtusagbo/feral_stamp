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
    this.rest = 0,
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

  /// 1 while the box is still the flat picker card, 0 once it is on the page.
  /// At rest it is a card: all four corners round, no wall, a soft lift rather
  /// than a contact shadow. Those resolve into the box as this falls to 0.
  final double rest;

  /// Content drawn on the top face. Null leaves it blank.
  final Widget? face;

  static const _topRadius = 28.0;

  /// Big: the front wall turns under into the base rather than meeting it at
  /// a corner, which is most of what makes the block read as a solid.
  static const _heelRadius = 44.0;
  static const _edge = 11.0;

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
          if (rest < 0.98)
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

  /// The lid. At rest it is the whole card and rounds on every corner; on the
  /// page its bottom edge is the crease into the front wall and squares off.
  /// It also sits a shade lighter at rest, where nothing is casting on it.
  Widget _top() {
    final bottom = Radius.circular(_topRadius * rest);
    return Container(
      width: width,
      height: depth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(_topRadius),
          topRight: const Radius.circular(_topRadius),
          bottomLeft: bottom,
          bottomRight: bottom,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFFEBEBEF), const Color(0xFFF4F4F6), rest)!,
            Color.lerp(const Color(0xFFF2F2F5), const Color(0xFFFAFAFB), rest)!,
            Color.lerp(const Color(0xFFF6F6F8), const Color(0xFFFDFDFD), rest)!,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: face,
    );
  }

  /// The front face. The rubber is the bottom strip of this same quad, and the
  /// whole thing is clipped by the heel radius, so the strip's ends follow the
  /// corner arc and taper as the footprint curves away: a crescent, which is
  /// what the base of a rounded block looks like from above. Drawn as its own
  /// bar it reads as a flat strip glued on.
  Widget _front() {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_heelRadius),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
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
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x24000000),
                            Color(0x06000000),
                            Color(0x00000000),
                            Color(0x10000000),
                          ],
                          stops: [0.0, 0.16, 0.70, 1.0],
                        ),
                      ),
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
                // A lit lip along the bottom of the wall, just above the rubber.
                const SizedBox(
                  height: 1.5,
                  child: ColoredBox(color: Color(0xFFF7F7F9)),
                ),
                const SizedBox(
                  height: _edge,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3A3A44), Color(0xFF15151B)],
                      ),
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Lies flat on the page, offset a little towards the viewer. A blurred
  /// shadow on the footprint rather than a gradient fill: a radial gradient
  /// reaches transparent at half the shortest side, which is inside the box's
  /// own outline, so nothing of it ever showed.
  ///
  /// At rest this is the card's only shadow, and it is a lift, not a drop:
  /// light, wide, and pushed down a little. On the page it tightens and
  /// darkens, then spreads and fades again as the box is raised.
  Widget _shadow() {
    final t = (lift / 120).clamp(0.0, 1.0);
    final ground = 1 - rest;
    final strength = (1 - t * 0.7) * (0.35 + 0.65 * ground);
    return Container(
      width: width,
      height: depth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_heelRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26 * strength),
            blurRadius: 34 + t * 30 + rest * 26,
            spreadRadius: 14 + t * 16 - rest * 10,
            offset: Offset(0, 20 * rest),
          ),
        ],
      ),
    );
  }

  /// A tight dark shadow hugging the base, gone almost as soon as the box
  /// leaves the page: the cue for the moment of contact. There is no page to
  /// contact at rest, so it only exists once the camera has tilted.
  Widget _contact() {
    final t = (lift / 40).clamp(0.0, 1.0);
    final ground = 1 - rest;
    return Container(
      width: width,
      height: depth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_heelRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34 * (1 - t) * ground),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}
