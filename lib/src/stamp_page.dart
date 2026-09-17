import 'dart:ui' show ImageByteFormat, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'invoice.dart';
import 'invoice_pdf.dart';
import 'stamp_sound.dart';
import 'theme.dart';
import 'timeline.dart';
import 'widgets/invoice_sheet.dart';
import 'widgets/stamp_cube.dart';
import 'widgets/controls.dart';
import 'widgets/stamp_face.dart';
import 'widgets/unclamped.dart';

/// Identifies the perspective transform wrapping the paper, so tests can read
/// the camera matrix instead of eyeballing a screenshot.
const cameraKey = Key('stamp-camera');

class StampPage extends StatefulWidget {
  const StampPage({super.key, this.sound});

  /// Defaults to the real thud. Tests pass [StampSound.silent].
  final StampSound? sound;

  @override
  State<StampPage> createState() => _StampPageState();
}

class _StampPageState extends State<StampPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: Timeline.total),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() {});
      });

  DateTime _date = DateTime(2026, 9, 15);
  StampLabel _label = StampLabel.paid;
  Color _color = Tone.stamp;
  bool _voided = false;
  bool _confirmed = false;

  late final StampSound _sound = widget.sound ?? StampSound();
  bool _dinged = false;
  int _stamps = 0;
  bool _thudded = false;

  Animation<double> _phase(int start, int len, Curve curve) =>
      CurvedAnimation(parent: _c, curve: Timeline.span(start, len, curve));

  late final Animation<double> _tilt = _phase(
    0,
    Timeline.tilt,
    Curves.easeInOutCubic,
  );
  late final Animation<double> _press = _phase(
    Timeline.pressAt,
    Timeline.press,
    Curves.easeIn,
  );
  late final Animation<double> _lift = _phase(
    Timeline.liftAt,
    Timeline.lift,
    Curves.easeOutCubic,
  );
  late final Animation<double> _rise = _phase(
    Timeline.riseAt,
    Timeline.rise,
    Curves.easeInOutCubic,
  );

  /// Ink bleeds in over the first slice of the lift, just after contact.
  late final Animation<double> _bleed = _phase(
    Timeline.liftAt,
    190,
    Curves.easeOutCubic,
  );

  /// Where the press parks: the end of the lift, with the page still tilted
  /// under the toast. The camera rise beyond it belongs to Done.
  static const _parked = Timeline.riseAt / Timeline.total;

  /// The stamp is on the page and the toast is up.
  bool get _landed => _c.value >= _parked - 1e-6;

  /// The camera has risen: the flat, finished page.
  bool get _finished => _c.value >= 1 - 1e-6;

  Stage get _stage {
    if (_c.isDismissed) return Stage.picking;
    if (_landed) return Stage.stamped;
    return Stage.pressing;
  }

  String get _headLabel =>
      _voided && _stage != Stage.picking ? 'VOID' : _label.head;
  Color get _inkColor => _voided ? Tone.stamp : _color;

  void _stamp({bool voided = false}) {
    if (_stage != Stage.picking) return;
    _sound.tick();
    setState(() {
      _voided = voided;
      _stamps++;
      _thudded = false;
      _dinged = false;
    });
    _c.animateTo(_parked);
  }

  void _clear() {
    setState(() {
      _voided = false;
      _confirmed = false;
    });
  }

  /// Runs the press backwards to the picker.
  void _undo() {
    _sound.tick();
    _clear();
    _c.reverse();
  }

  /// Straight to a fresh picker. No animation: the press is not being
  /// undone, this is the next job.
  void _next() {
    _clear();
    _c.value = 0;
  }

  void _done() {
    _sound.tick();
    setState(() => _confirmed = true);
    _c.animateTo(1);
  }

  @override
  void initState() {
    super.initState();
    // A global handler rather than a focus node: tapping a chip or a swatch
    // must not quietly kill the Enter shortcut.
    HardwareKeyboard.instance.addHandler(_onKey);

    // The thud fires when the rubber meets the paper, which is the end of the
    // press phase, not the moment the button was pressed. The ding follows
    // once the thud has finished (it runs 170ms) plus a short beat, as the
    // stamp is lifting away; the two never overlap.
    _c.addListener(() {
      if (_c.status != AnimationStatus.forward) return;
      if (!_thudded && _c.value >= Timeline.liftAt / Timeline.total) {
        _thudded = true;
        _sound.thud(_stamps);
      }
      if (!_dinged && _c.value >= (Timeline.liftAt + 260) / Timeline.total) {
        _dinged = true;
        _sound.ding(_stamps);
      }
    });

    // Debug affordance: ?t=0.46 parks the timeline at that point so a frame
    // can be inspected in a real browser without driving the press.
    final park = double.tryParse(Uri.base.queryParameters['t'] ?? '');
    if (park != null) {
      _c.value = park.clamp(0.0, 1.0);
      // Past the parking point only Done can take it, so the state matches.
      _confirmed = _c.value > _parked + 0.01;
    }
  }

  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    if (e.logicalKey != LogicalKeyboardKey.enter) return false;
    if (_stage != Stage.picking) return false;
    _stamp();
    return true;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _sound.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tone.page,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(),
                  const SizedBox(height: 60),
                  _scene(),
                  SizedBox(height: _confirmed ? 26 : 38),
                  _controls(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _header() {
    final done = _landed;
    return Column(
      children: [
        Text(
          '${Invoice.billTo.toUpperCase()} · ${Invoice.total}',
          style: Type.eyebrow,
        ),
        const SizedBox(height: 4),
        const Text('Invoice ${Invoice.id}', style: Type.title),
        const SizedBox(height: 6),
        SizedBox(
          width: 560,
          child: done
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _inkColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _voided
                            ? 'Voided on ${_date.longLine}'
                            : '${_label.past} on ${_date.longLine}',
                        style: Type.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (_confirmed) ...[
                      const Text(' · ', style: Type.body),
                      // On the finished page this is a way out, not a rewind:
                      // it behaves like Next invoice.
                      GestureDetector(
                        onTap: _next,
                        child: Text(
                          'Undo',
                          style: Type.body.copyWith(
                            color: const Color(0xFF2F6BFF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : const Text(
                  "Choose the payment date. It's printed on the "
                  'invoice and saved to its history.',
                  style: Type.body,
                  textAlign: TextAlign.center,
                ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- scene

  /// One perspective transform holds both the paper and the head, and there is
  /// only ever *one* head: the picker tips into 3D and becomes the stamp. That
  /// continuity is the whole trick, so it must not be faked with a crossfade
  /// between two separate widgets.
  Widget _scene() {
    // Tilt in, then back out again as the camera rises at the end.
    final t = _tilt.value;
    final camera = (t - _rise.value).clamp(0.0, 1.0);
    final angle = camera * 0.80;

    // Perspective comes in with the tilt so the box sits flat and undistorted
    // while it is still the picker.
    final perspective = 0.0009 * t;

    final camera3d = Matrix4.identity()
      ..setEntry(3, 2, perspective)
      ..rotateX(-angle);

    // The rubber rebounds off the paper, then the box accelerates away.
    final bounce =
        Curves.easeOutCubic.transform((_lift.value * 3).clamp(0.0, 1.0)) *
        Beat.bounce;
    final settle = (1 - _press.value) + bounce;
    final exit = Curves.easeInCubic.transform(_lift.value);

    // The box is a real object on the page: it hovers above the mark along
    // the page's normal and descends onto it. Leaving is a screen-space rise
    // applied outside the camera, which is what the reference does.
    const markOnPage = Offset(74, 126);
    const hoverLift = 65.0;
    final position = Offset.lerp(Offset.zero, markOnPage, t)!;
    final lift = hoverLift * t * settle;

    final exitOffset = Offset(0, -exit * 430);

    // At rest the card is bigger than the box is on the page: the camera
    // pulls back as the page comes into view. Measured off the reference.
    final exitScale = (1 + 0.16 * exit) * lerpDouble(2.0, 1.0, t)!;

    // The toast straddles the page's bottom edge. The frame grows by the
    // overlap while the page is tilted and gives it back as the camera rises.
    final hang = 72.0 * (t - _rise.value).clamp(0.0, 1.0);

    return SizedBox(
      height: lerpDouble(268, 356, t)! + _rise.value * 125 + hang,
      width: 620,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: hang,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (t > 0.01)
                  Unclamped(
                    child: Opacity(
                      opacity: Curves.easeOut.transform(t.clamp(0.0, 1.0)),
                      child: Transform(
                        key: cameraKey,
                        alignment: Alignment.center,
                        transform: camera3d,
                        // The sheet is designed at a readable width and scaled up so
                        // the page reads large against the head, as in the reference.
                        child: Transform.scale(
                          scale: 1.18,
                          child: InvoiceSheet(
                            headText: _headLabel,
                            date: _date,
                            color: _inkColor,
                            bleed: _bleed.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Opacity sits inside the transforms, not outside them: a proxy box
                // rejects pointers beyond its own unscaled bounds before a scale
                // below it could map them back, which left the outer wheel columns
                // unreachable once the resting card was scaled up.
                Unclamped(
                  child: Transform.translate(
                    offset: exitOffset,
                    child: Transform.scale(
                      scale: exitScale,
                      child: Opacity(
                        opacity: (1 - (_lift.value - 0.55) / 0.45).clamp(
                          0.0,
                          1.0,
                        ),
                        child: StampCube(
                          angle: angle,
                          perspective: perspective,
                          position: position,
                          lift: lift,
                          rest: 1 - t,
                          width: Box.width,
                          depth: Box.depth,
                          height: Box.height,
                          face: StampFace(
                            date: _date,
                            headText: _headLabel,
                            color: _color,
                            background: StampCube.lidTone(1 - t),
                            interactive: _stage == Stage.picking,
                            onDateChanged: (d) {
                              _sound.roll();
                              setState(() => _date = d);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_landed && !_confirmed) Positioned(bottom: 0, child: _toast()),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- controls

  Widget _controls() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Center(
        child: _finished
            ? _finalActions()
            : _landed
            ? const SizedBox.shrink()
            : Opacity(
                opacity: (1 - _tilt.value * 1.6).clamp(0.0, 1.0),
                child: _picker(),
              ),
      ),
    );
  }

  Widget _picker() {
    return Column(
      children: [
        Text(
          _date.longLine,
          style: Type.body.copyWith(
            color: Tone.text,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 24),
        // Wraps so the tray and the swatches stack on a narrow screen instead
        // of running off the edge.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 12,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Tone.chipTray,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final l in StampLabel.values)
                    LabelChip(
                      text: l.chip,
                      selected: l == _label,
                      onTap: () => setState(() => _label = l),
                    ),
                ],
              ),
            ),
            Container(width: 1, height: 30, color: Tone.cardEdge),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in Tone.swatches) ...[
                  InkSwatch(
                    color: c,
                    selected: c == _color,
                    onTap: () => setState(() => _color = c),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 22),
        GestureDetector(
          onTap: _stamp,
          onLongPress: () => _stamp(voided: true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 15),
            decoration: BoxDecoration(
              color: Tone.text,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _label.action,
              style: const TextStyle(
                fontFamily: 'Helvetica Neue',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'or press Enter · hold to void',
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 12,
            color: Tone.muted,
          ),
        ),
      ],
    );
  }

  Widget _toast() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Tone.cardEdge),
        boxShadow: paperShadow(0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: _inkColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            '${_voided ? 'Voided' : _label.past} · ${_date.shortLine}',
            style: const TextStyle(
              fontFamily: 'Helvetica Neue',
              fontSize: 16,
              color: Tone.text,
            ),
          ),
          const SizedBox(width: 16),
          PillButton(text: 'Undo', onTap: _undo),
          const SizedBox(width: 6),
          PillButton(text: 'Done', filled: true, onTap: _done),
        ],
      ),
    );
  }

  /// The PDF carries a picture of the stamp exactly as it printed on screen,
  /// erosion and all, rather than a clean vector redraw of it.
  Future<void> _download() async {
    final boundary =
        InvoiceSheet.stampKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    final image = await boundary?.toImage(pixelRatio: 4);
    final png = (await image?.toByteData(format: ImageByteFormat.png))?.buffer
        .asUint8List();
    await downloadInvoicePdf(stampPng: png);
  }

  Widget _finalActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PillButton(text: 'Download PDF', large: true, onTap: _download),
        const SizedBox(width: 14),
        PillButton(
          text: 'Next invoice',
          filled: true,
          large: true,
          onTap: _next,
        ),
      ],
    );
  }
}
