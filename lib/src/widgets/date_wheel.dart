import 'package:flutter/material.dart';

import '../theme.dart';

/// One scrollable column of the stamp's date roller.
///
/// Five rows are visible. The centre row sits in a grey pill and is the
/// selected value; the rest fall away in opacity and size so the column reads
/// as a physical wheel rather than a list.
class DateWheel extends StatefulWidget {
  const DateWheel({
    super.key,
    required this.values,
    required this.index,
    required this.onChanged,
    required this.axisLabel,
    this.width = 74,
    this.enabled = true,
  });

  final List<String> values;
  final int index;
  final ValueChanged<int> onChanged;
  final String axisLabel;
  final double width;
  final bool enabled;

  static const rowHeight = 27.0;
  static const visibleRows = 5;
  static const viewportHeight = rowHeight * visibleRows;

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
          height: DateWheel.viewportHeight,
          child: Stack(
            children: [
              // The selection pill sits behind the numbers.
              Center(
                child: Container(
                  height: DateWheel.rowHeight - 2,
                  decoration: BoxDecoration(
                    color: Tone.wheelPill,
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: DateWheel.rowHeight,
                physics: widget.enabled
                    ? const FixedExtentScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                diameterRatio: 1.5,
                perspective: 0.004,
                squeeze: 1.06,
                overAndUnderCenterOpacity: 0.28,
                onSelectedItemChanged: widget.onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.values.length,
                  builder: (context, i) =>
                      Center(child: Text(widget.values[i], style: Type.wheel)),
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
                          Tone.card,
                          Tone.card.withValues(alpha: 0.55),
                          Tone.card.withValues(alpha: 0),
                          Tone.card.withValues(alpha: 0),
                          Tone.card.withValues(alpha: 0.55),
                          Tone.card,
                        ],
                        stops: const [0.0, 0.14, 0.30, 0.70, 0.86, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(widget.axisLabel, style: Type.axis),
      ],
    );
  }
}
