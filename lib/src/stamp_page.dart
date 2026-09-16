import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'invoice.dart';
import 'theme.dart';
import 'widgets/invoice_sheet.dart';
import 'widgets/stamp_head.dart';

/// Where we are in the press. The whole animation is one timeline; this enum
/// just names the regions so the UI can decide what to show.
enum Stage { picking, pressing, stamped }

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

  String get _headLabel => _voided ? 'VOID' : _label.head;
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
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tone.page,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (e) {
          if (e is KeyDownEvent &&
              e.logicalKey == LogicalKeyboardKey.enter &&
              _stage == Stage.picking) {
            _stamp();
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _header(),
                    const SizedBox(height: 18),
                    _scene(),
                    const SizedBox(height: 18),
                    _controls(),
                  ],
                ),
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

  /// Both the paper and the head live inside one perspective transform, so the
  /// head genuinely descends *into* the scene rather than sliding over a
  /// picture of it.
  Widget _scene() {
    // Tilt in, then back out as the camera rises.
    final camera = (_tilt.value - _rise.value).clamp(0.0, 1.0);
    final angle = camera * 0.60;

    // The head hovers, drops to the paper, then leaves upward.
    const hover = 150.0;
    final bounce = Curves.easeOut.transform(_lift.value) * Beat.bounce;
    final z = hover * (1 - _press.value) + hover * bounce;
    final exit = _lift.value * 520;

    final sheetVisible = _tilt.value > 0.02;

    return SizedBox(
      height: 470,
      width: 360,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..rotateX(angle),
            child: Opacity(
              opacity: sheetVisible ? 1 : 0,
              child: InvoiceSheet(
                headText: _headLabel,
                date: _date,
                color: _inkColor,
                bleed: _bleed.value,
              ),
            ),
          ),
          if (sheetVisible)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: (1 - _lift.value).clamp(0.0, 1.0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0014)
                        ..rotateX(angle)
                        ..translateByDouble(0.0, -120.0 - exit, z, 1.0),
                      child: StampHead(
                        date: _date,
                        headText: _headLabel,
                        color: _inkColor,
                        interactive: false,
                        showUnderside: true,
                        onDateChanged: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // The flat picker, cross-faded out as the camera tilts.
          if (_tilt.value < 0.98)
            Opacity(
              opacity: (1 - _tilt.value * 1.4).clamp(0.0, 1.0),
              child: StampHead(
                date: _date,
                headText: _label.head,
                color: _color,
                interactive: _stage == Stage.picking,
                onDateChanged: (d) => setState(() => _date = d),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- controls

  Widget _controls() {
    if (_c.isCompleted) {
      return _confirmed ? _finalActions() : _toast();
    }
    return Opacity(
      opacity: (1 - _tilt.value * 1.6).clamp(0.0, 1.0),
      child: _picker(),
    );
  }

  Widget _picker() {
    return Column(
      children: [
        Text(_date.longLine, style: Type.body),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in StampLabel.values) ...[
              _Chip(
                text: l.chip,
                selected: l == _label,
                onTap: () => setState(() => _label = l),
              ),
              const SizedBox(width: 6),
            ],
            const SizedBox(width: 10),
            for (final c in Tone.swatches) ...[
              _Swatch(
                color: c,
                selected: c == _color,
                onTap: () => setState(() => _color = c),
              ),
              const SizedBox(width: 6),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Tone.text : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Tone.cardEdge),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Tone.muted,
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
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Tone.text : Colors.transparent,
            width: 1.6,
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
