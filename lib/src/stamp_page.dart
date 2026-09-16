import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'invoice.dart';
import 'theme.dart';
import 'widgets/invoice_sheet.dart';
import 'widgets/stamp_head.dart';

/// Where we are in the press. The whole animation is one timeline; this enum
/// just names the regions so the UI can decide what to show.
enum Stage { picking, pressing, stamped }

/// Identifies the perspective transform wrapping the paper, so tests can read
/// the camera matrix instead of eyeballing a screenshot.
const cameraKey = Key('stamp-camera');

/// Timeline offsets, derived from the reference component's own control panel:
/// camera tilt 0.80s, press 0.15s, lift away 0.42s, camera rise 0.70s.
class _T {
  static const tilt = 800;
  static const press = 150;
  static const lift = 420;
  static const rise = 700;

  static const pressAt = tilt;
  static const liftAt = pressAt + press;
  static const riseAt = liftAt + lift;
  static const total = riseAt + rise;

  static Interval span(int start, int len, [Curve c = Curves.linear]) =>
      Interval(start / total, (start + len) / total, curve: c);
}

class StampPage extends StatefulWidget {
  const StampPage({super.key});

  @override
  State<StampPage> createState() => _StampPageState();
}

class _StampPageState extends State<StampPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: _T.total),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() {});
      });

  DateTime _date = DateTime(2026, 9, 15);
  StampLabel _label = StampLabel.paid;
  Color _color = Tone.stamp;
  bool _voided = false;
  bool _confirmed = false;

  Animation<double> _phase(int start, int len, Curve curve) =>
      CurvedAnimation(parent: _c, curve: _T.span(start, len, curve));

  late final Animation<double> _tilt = _phase(
    0,
    _T.tilt,
    Curves.easeInOutCubic,
  );
  late final Animation<double> _press = _phase(
    _T.pressAt,
    _T.press,
    Curves.easeIn,
  );
  late final Animation<double> _lift = _phase(
    _T.liftAt,
    _T.lift,
    Curves.easeOutCubic,
  );
  late final Animation<double> _rise = _phase(
    _T.riseAt,
    _T.rise,
    Curves.easeInOutCubic,
  );

  /// Ink bleeds in over the first slice of the lift, just after contact.
  late final Animation<double> _bleed = _phase(
    _T.liftAt,
    190,
    Curves.easeOutCubic,
  );

  Stage get _stage {
    if (_c.isDismissed) return Stage.picking;
    if (_c.isCompleted) return Stage.stamped;
    return Stage.pressing;
  }

  String get _headLabel =>
      _voided && _stage != Stage.picking ? 'VOID' : _label.head;
  Color get _inkColor => _voided ? Tone.stamp : _color;

  void _stamp({bool voided = false}) {
    if (_stage != Stage.picking) return;
    setState(() => _voided = voided);
    _c.forward();
  }

  void _undo() {
    setState(() {
      _voided = false;
      _confirmed = false;
    });
    _c.reverse();
  }

  @override
  void initState() {
    super.initState();
    // A global handler rather than a focus node: tapping a chip or a swatch
    // must not quietly kill the Enter shortcut.
    HardwareKeyboard.instance.addHandler(_onKey);
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
                  const SizedBox(height: 10),
                  _scene(),
                  const SizedBox(height: 18),
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
    final done = _c.isCompleted;
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
          width: 330,
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
    final angle = camera * 0.66;

    final camera3d = Matrix4.identity()
      ..setEntry(3, 2, 0.0016)
      ..rotateX(-angle);

    // The rubber rebounds off the paper, then the head accelerates away.
    final bounce =
        Curves.easeOutCubic.transform((_lift.value * 3).clamp(0.0, 1.0)) *
        Beat.bounce;
    final settle = (1 - _press.value) + bounce;
    final exit = Curves.easeInCubic.transform(_lift.value);

    // Only the page is in the tilted plane. The head stays square to the
    // viewer and is simply positioned over the page, which is what the
    // reference does: rotating it too foreshortens the block into a wedge that
    // swallows the paper.
    //
    // Its resting spot is derived by pushing the mark's position on the page
    // through the same camera, so the two stay aligned at any tilt angle.
    const markOnPage = Offset(83, 176);
    const padOffset = 150.0;
    final markOnScreen = MatrixUtils.transformPoint(camera3d, markOnPage);
    final rest = Offset(markOnScreen.dx, markOnScreen.dy - padOffset);

    const hoverLift = 150.0;
    final offset =
        Offset.lerp(Offset.zero, rest, t)! -
        Offset(0, hoverLift * t * settle) -
        Offset(0, exit * 430);

    final scale = (1 + 0.05 * t * settle) * (1 + 0.16 * exit);

    return SizedBox(
      height: lerpDouble(268, 700, t)!,
      width: 620,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (t > 0.01)
            _Unclamped(
              child: Opacity(
                opacity: Curves.easeOut.transform(t.clamp(0.0, 1.0)),
                child: Transform(
                  key: cameraKey,
                  alignment: Alignment.center,
                  transform: camera3d,
                  // The sheet is designed at a readable width and scaled up so
                  // the page reads large against the head, as in the reference.
                  child: Transform.scale(
                    scale: 1.4,
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
          _Unclamped(
            child: Opacity(
              opacity: (1 - (_lift.value - 0.55) / 0.45).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: offset,
                child: Transform.scale(
                  scale: scale,
                  child: StampHead(
                    date: _date,
                    headText: _headLabel,
                    color: _color,
                    interactive: _stage == Stage.picking,
                    solid: t > 0.04,
                    onDateChanged: (d) => setState(() => _date = d),
                  ),
                ),
              ),
            ),
          ),
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
        child: _c.isCompleted
            ? (_confirmed ? _finalActions() : _toast())
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
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
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
                    _Chip(
                      text: l.chip,
                      selected: l == _label,
                      onTap: () => setState(() => _label = l),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in Tone.swatches) ...[
                  _Swatch(
                    color: c,
                    selected: c == _color,
                    onTap: () => setState(() => _color = c),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _stamp,
          onLongPress: () => _stamp(voided: true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            decoration: BoxDecoration(
              color: Tone.text,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _label.action,
              style: const TextStyle(
                fontFamily: 'Helvetica Neue',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'or press Enter · hold to void',
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 10,
            color: Tone.muted,
          ),
        ),
      ],
    );
  }

  Widget _toast() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 7, 7, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Tone.cardEdge),
        boxShadow: paperShadow(0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: _inkColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '${_voided ? 'Voided' : _label.past} · ${_date.shortLine}',
            style: const TextStyle(
              fontFamily: 'Helvetica Neue',
              fontSize: 12,
              color: Tone.text,
            ),
          ),
          const SizedBox(width: 12),
          _Pill(text: 'Undo', onTap: _undo),
          const SizedBox(width: 6),
          _Pill(
            text: 'Done',
            filled: true,
            onTap: () => setState(() => _confirmed = true),
          ),
        ],
      ),
    );
  }

  Widget _finalActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pill(text: 'Download PDF', onTap: () {}),
        const SizedBox(width: 8),
        _Pill(text: 'Next invoice', filled: true, onTap: _undo),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Tone.text : Tone.muted,
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.onTap, this.filled = false});

  final String text;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? Tone.text : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Tone.cardEdge),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: filled ? Colors.white : Tone.text,
          ),
        ),
      ),
    );
  }
}

/// Hands its child unbounded constraints so it keeps its natural size inside a
/// smaller animated frame.
class _Unclamped extends StatelessWidget {
  const _Unclamped({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => OverflowBox(
    minWidth: 0,
    minHeight: 0,
    maxWidth: double.infinity,
    maxHeight: double.infinity,
    child: child,
  );
}
