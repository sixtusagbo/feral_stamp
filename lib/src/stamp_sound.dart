import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// When the thud plays. Mirrors the reference's control: on every press, on
/// the first press only, or never. [muted] is a master switch on top.
enum SoundMode { every, first, never }

/// The stamp's thud: a short, low, pitch-dropping body with a slap on the
/// front, synthesised into `assets/sounds/thud.wav`. Played at the moment of
/// contact, not at the press, so it lands with the ink.
///
/// [StampSound.silent] has the same controls and never touches audio. Widget
/// tests use it: the audio plugin initialises asynchronously and, with no
/// platform underneath it, that failure cannot be caught from here.
class StampSound {
  StampSound() : _player = AudioPlayer() {
    // Warm the player so the first thud is not late.
    unawaited(_player!.setSource(_source).catchError((_) {}));
  }

  StampSound.silent() : _player = null;

  static final _source = AssetSource('sounds/thud.wav');
  final AudioPlayer? _player;

  SoundMode mode = SoundMode.every;
  bool muted = false;

  /// [stampNumber] is 1 for the first press of the session.
  void thud(int stampNumber) {
    final player = _player;
    if (player == null || muted || mode == SoundMode.never) return;
    if (mode == SoundMode.first && stampNumber != 1) return;
    unawaited(
      player
          .stop()
          .then((_) => player.play(_source, volume: 0.9))
          .catchError((_) {}),
    );
  }

  void dispose() {
    final player = _player;
    if (player != null) unawaited(player.dispose().catchError((_) {}));
  }
}
