import 'package:flutter/material.dart';

/// Design tokens lifted from the FeralUI Stamp reference.
class Tone {
  const Tone._();

  /// The stamp impression colour, sampled from the reference (`rgb(216,52,43)`).
  static const stamp = Color(0xFFD8342B);

  static const page = Color(0xFFF2F2F3);
  static const paper = Color(0xFFFCFCFC);
  static const card = Color(0xFFF7F7F8);
  static const cardEdge = Color(0xFFE2E2E5);
  static const cardUnder = Color(0xFF14141A);

  static const text = Color(0xFF16161A);
  static const muted = Color(0xFF8A8A93);
  static const hairline = Color(0xFFE6E6E9);

  /// The grey slab behind the selected row of each wheel.
  static const wheelPill = Color(0xFFE9E9EC);

  /// The tray the label chips sit in.
  static const chipTray = Color(0xFFECECEF);

  static const swatches = <Color>[
    stamp,
    Color(0xFF2F6BFF),
    Color(0xFF15A163),
    Color(0xFF7A4DE8),
    Color(0xFF16161A),
  ];
}

/// Durations exposed by the reference component's own control panel.
class Beat {
  const Beat._();

  static const cameraTilt = Duration(milliseconds: 800);
  static const press = Duration(milliseconds: 150);
  static const liftAway = Duration(milliseconds: 420);
  static const cameraRise = Duration(milliseconds: 700);

  /// Overshoot applied to the press, as a fraction of the travel.
  static const bounce = 0.30;
}

class Type {
  const Type._();

  static const _family = 'Helvetica Neue';

  static const title = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: Tone.text,
    height: 1.15,
  );

  static const eyebrow = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.2,
    color: Tone.muted,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    color: Tone.muted,
    height: 1.45,
  );

  static const wheel = TextStyle(
    fontFamily: _family,
    fontSize: 25,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: Tone.text,
  );

  static const axis = TextStyle(
    fontFamily: _family,
    fontSize: 9.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: Tone.muted,
  );
}
