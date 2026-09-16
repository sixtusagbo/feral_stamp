import 'package:flutter/material.dart';

import '../theme.dart';

/// One scrollable column of the stamp's date roller.
///
/// Three rows are visible at a time. The centre row sits inside a pill and is
/// the selected value; the neighbours fade and shrink as they roll past, which
/// is what sells the thing as a physical wheel rather than a list.
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

  static const rowHeight = 30.0;
  static const visibleRows = 3;
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: DateWheel.rowHeight,
                physics: widget.enabled
                    ? const FixedExtentScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                diameterRatio: 1.35,
                perspective: 0.006,
                overAndUnderCenterOpacity: 0.34,
                onSelectedItemChanged: widget.onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.values.length,
                  builder: (context, i) =>
                      Center(child: Text(widget.values[i], style: Type.wheel)),
                ),
              ),
              // Feather the top and bottom so values roll out of view.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Tone.card,
                          Tone.card.withValues(alpha: 0),
                          Tone.card.withValues(alpha: 0),
                          Tone.card,
                        ],
                        stops: const [0.0, 0.26, 0.74, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(widget.axisLabel, style: Type.axis),
      ],
    );
  }
}
