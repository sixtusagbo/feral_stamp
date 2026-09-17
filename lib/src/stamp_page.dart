import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'invoice.dart';
import 'invoice_pdf.dart';
import 'stamp_sound.dart';
import 'theme.dart';
import 'timeline.dart';
import 'widgets/final_actions.dart';
import 'widgets/invoice_sheet.dart';
import 'widgets/picker_controls.dart';
import 'widgets/stamp_header.dart';
import 'widgets/stamp_scene.dart';
import 'widgets/stamp_toast.dart';

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
        if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
          setState(() {});
        }
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

  /// The width everything is designed at. Narrower viewports scale it down.
  static const _stageWidth = 660.0;

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
    // The composition is laid out at desktop width. Only a viewport narrower
    // than that (a phone) scales it down as a whole; desktop is untouched.
    final narrow = MediaQuery.sizeOf(context).width < _stageWidth;

    Widget stage = AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StampHeader(
            landed: _landed,
            confirmed: _confirmed,
            voided: _voided,
            label: _label,
            date: _date,
            ink: _inkColor,
            onUndo: _next,
          ),
          const SizedBox(height: 60),
          StampScene(
            tilt: _tilt.value,
            press: _press.value,
            lift: _lift.value,
            rise: _rise.value,
            bleed: _bleed.value,
            date: _date,
            headText: _headLabel,
            ink: _inkColor,
            color: _color,
            interactive: _stage == Stage.picking,
            onDateChanged: (d) {
              _sound.roll();
              setState(() => _date = d);
            },
            toast: _landed && !_confirmed
                ? StampToast(
                    text:
                        '${_voided ? 'Voided' : _label.past} · '
                        '${_date.shortLine}',
                    ink: _inkColor,
                    onUndo: _undo,
                    onDone: _done,
                  )
                : null,
          ),
          SizedBox(height: _confirmed ? 26 : 38),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: Center(
              child: _finished
                  ? FinalActions(onDownload: _download, onNext: _next)
                  : _landed
                  ? const SizedBox.shrink()
                  : Opacity(
                      opacity: (1 - _tilt.value * 1.6).clamp(0.0, 1.0),
                      child: PickerControls(
                        date: _date,
                        label: _label,
                        color: _color,
                        onLabel: (l) => setState(() => _label = l),
                        onColor: (c) => setState(() => _color = c),
                        onStamp: _stamp,
                        onVoid: () => _stamp(voided: true),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );

    if (narrow) {
      stage = FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(width: _stageWidth, child: stage),
      );
    }

    return Scaffold(
      backgroundColor: Tone.page,
      body: SafeArea(
        child: Center(child: SingleChildScrollView(child: stage)),
      ),
    );
  }
}
