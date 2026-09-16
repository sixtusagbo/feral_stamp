import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme.dart';

/// One scrollable column of the stamp's date roller.
///
/// Five rows are visible. The centre row sits in a grey pill and is the
/// selected value. The rows either side of it are crisp; the outermost pair
/// are blurred and faded, which is what sells the column as a wheel rolling
/// out of focus rather than a list being clipped.
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
              // The selection pill sits behind the numbers.
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
                // size and full strength in the reference.
                diameterRatio: 3.0,
                perspective: 0.001,
                squeeze: 1.0,
                overAndUnderCenterOpacity: 1.0,
                onSelectedItemChanged: widget.onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.values.length,
                  builder: (context, i) =>
                      Center(child: Text(widget.values[i], style: Type.wheel)),
                ),
              ),
              // The outermost rows are out of focus.
              for (final top in [true, false])
                Positioned(
                  top: top ? 0 : null,
                  bottom: top ? null : 0,
                  left: 0,
                  right: 0,
                  height: widget.rowHeight - 1,
                  child: IgnorePointer(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              // Feather the ends so values roll out of view rather than
              // stopping dead at the edge of the face.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.fade.withValues(alpha: 0.85),
                          widget.fade.withValues(alpha: 0.45),
                          widget.fade.withValues(alpha: 0),
                          widget.fade.withValues(alpha: 0),
                          widget.fade.withValues(alpha: 0.45),
                          widget.fade.withValues(alpha: 0.85),
                        ],
                        stops: const [0.0, 0.16, 0.26, 0.74, 0.84, 1.0],
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
