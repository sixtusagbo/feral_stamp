import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// When the stamp's own sounds play: on every press, on the first press only,
/// or never. [muted] is a master switch over everything, ticks included. Both
/// are settings on the component; the demo page does not surface them.
enum SoundMode { every, first, never }

/// The four cues, all synthesised into `assets/sounds/`:
///
/// - **tick**: a soft "tun" on every control: chips, swatches, the button.
/// - **roll**: a dry ratchet clack on each detent as a wheel turns, the sound
///   of a number reel. Two players alternate so a fast spin does not choke
///   on restarting one.
/// - **thud**: the "kpum" as the rubber meets the paper, at the end of the
///   press phase rather than when the button was hit, so it lands with the
///   ink.
/// - **ding**: a small bell as the stamp lifts away, the moment it is done.
///
/// Each has its own player so they can overlap: the ding starts while the
/// thud's tail is still ringing.
///
/// [StampSound.silent] has the same controls and never touches audio. Widget
/// tests use it: the audio plugin initialises asynchronously and, with no
/// platform underneath it, that failure cannot be caught from here.
class StampSound {
  StampSound() : _players = _Players.live() {
    // Warm the players so the first cue is not late.
    final p = _players!;
    for (final (player, source) in [
      (p.tick, _tickSrc),
      (p.roll[0], _rollSrc),
      (p.roll[1], _rollSrc),
      (p.thud, _thudSrc),
      (p.ding, _dingSrc),
    ]) {
      unawaited(player.setSource(source).catchError((_) {}));
    }
  }

  StampSound.silent() : _players = null;

  static final _tickSrc = AssetSource('sounds/tick.wav');
  static final _rollSrc = AssetSource('sounds/roll.wav');
  static final _thudSrc = AssetSource('sounds/thud.wav');
  static final _dingSrc = AssetSource('sounds/ding.wav');

  final _Players? _players;
  int _rollTurn = 0;

  SoundMode mode = SoundMode.every;
  bool muted = false;

  void _fire(AudioPlayer player, Source source, double volume) {
    if (muted) return;
    unawaited(
      player
          .stop()
          .then((_) => player.play(source, volume: volume))
          .catchError((_) {}),
    );
  }

  /// Whether the stamp's own cues play for this press. [stampNumber] is 1
  /// for the first press of the session.
  bool _stampCues(int stampNumber) {
    if (mode == SoundMode.never) return false;
    if (mode == SoundMode.first && stampNumber != 1) return false;
    return true;
  }

  void tick() {
    final p = _players;
    if (p != null) _fire(p.tick, _tickSrc, 0.7);
  }

  void roll() {
    final p = _players;
    if (p == null) return;
    _rollTurn = (_rollTurn + 1) % p.roll.length;
    _fire(p.roll[_rollTurn], _rollSrc, 0.55);
  }

  void thud(int stampNumber) {
    final p = _players;
    if (p != null && _stampCues(stampNumber)) _fire(p.thud, _thudSrc, 0.9);
  }

  void ding(int stampNumber) {
    final p = _players;
    if (p != null && _stampCues(stampNumber)) _fire(p.ding, _dingSrc, 0.6);
  }

  void dispose() {
    final p = _players;
    if (p == null) return;
    for (final player in [p.tick, ...p.roll, p.thud, p.ding]) {
      unawaited(player.dispose().catchError((_) {}));
    }
  }
}

class _Players {
  _Players.live()
    : tick = AudioPlayer(),
      roll = [AudioPlayer(), AudioPlayer()],
      thud = AudioPlayer(),
      ding = AudioPlayer();

  final AudioPlayer tick;
  final List<AudioPlayer> roll;
  final AudioPlayer thud;
  final AudioPlayer ding;
}
