import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme.dart';

/// One scrollable column of the stamp's date roller.
///
/// Five rows are visible. The centre row sits in a grey pill and is the
/// selected value. Each row blurs and fades by its own distance from the
/// selection, continuously as the wheel turns, so the neighbours are crisp and
/// the outermost pair roll out of focus. Blurring the rows rather than a band
/// behind them keeps the effect attached to the values and leaves no visible
/// region edges on the lid.
class DateWheel extends StatefulWidget {
  const DateWheel({
    super.key,
    required this.values,
    required this.index,
    required this.onChanged,
    required this.axisLabel,
    this.width = 74,
    this.rowHeight = 25,
    this.fontSize = 21,
    this.fade = Tone.card,
    this.enabled = true,
  });

  final List<String> values;
  final int index;
  final ValueChanged<int> onChanged;
  final String axisLabel;
  final double width;
  final double rowHeight;
  final double fontSize;

  /// What the ends of the column fade into: the surface it sits on.
  final Color fade;
  final bool enabled;

  static const visibleRows = 5;
  double get viewportHeight => rowHeight * visibleRows;

  @override
  State<DateWheel> createState() => _DateWheelState();
}

class _DateWheelState extends State<DateWheel> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.index);

  @override
  void didUpdateWidget(DateWheel old) {
    super.didUpdateWidget(old);
    // Re-sync when the day is clamped from the outside (e.g. 31 -> 30).
    if (widget.index != old.index &&
        _controller.hasClients &&
        _controller.selectedItem != widget.index) {
      _controller.animateToItem(
        widget.index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The neighbours of the selection sit a shade lighter than it; from about
  /// one pitch out to two, rows blur and fade on top of that.
  Widget _row(int i) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final offset = _controller.hasClients
            ? _controller.offset
            : widget.index * widget.rowHeight;
        final distance = ((i * widget.rowHeight - offset) / widget.rowHeight)
            .abs();
        final k = ((distance - 1.15) / 0.85).clamp(0.0, 1.0);
        final near = distance.clamp(0.0, 1.0);

        Widget row = Center(
          child: Text(
            widget.values[i],
            style: Type.wheel.copyWith(fontSize: widget.fontSize),
          ),
        );
        if (k > 0.02) {
          row = ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2.6 * k, sigmaY: 2.6 * k),
            child: row,
          );
        }
        return Opacity(opacity: 1 - 0.2 * near - 0.45 * k, child: row);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.width,
          height: widget.viewportHeight,
          child: Stack(
            children: [
              // The pill stands a little taller than a row, as in the
              // reference, so it reads as a slot the value sits in.
              Center(
                child: Container(
                  height: widget.rowHeight + 3,
                  decoration: BoxDecoration(
                    color: Tone.wheelPill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: widget.rowHeight,
                physics: widget.enabled
                    ? const FixedExtentScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                // Nearly flat: the neighbours of the selected row are full
                // size in the reference.
                diameterRatio: 3.0,
                perspective: 0.001,
                overAndUnderCenterOpacity: 1.0,
                onSelectedItemChanged: widget.onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.values.length,
                  builder: (context, i) => _row(i),
                ),
              ),
              // A thin feather at the very ends so the outermost rows roll
              // off the face rather than stopping at its edge.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.fade,
                          widget.fade.withValues(alpha: 0),
                          widget.fade.withValues(alpha: 0),
                          widget.fade,
                        ],
                        stops: const [0.0, 0.10, 0.90, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.axisLabel,
          style: Type.axis.copyWith(fontSize: 6.5, letterSpacing: 1.1),
        ),
      ],
    );
  }
}
