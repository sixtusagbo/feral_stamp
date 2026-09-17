import 'package:flutter/material.dart';

import 'controls.dart';

/// What sits under the finished, flat page.
class FinalActions extends StatelessWidget {
  const FinalActions({
    super.key,
    required this.onDownload,
    required this.onNext,
  });

  final VoidCallback onDownload;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PillButton(text: 'Download PDF', large: true, onTap: onDownload),
        const SizedBox(width: 14),
        PillButton(
          text: 'Next invoice',
          filled: true,
          large: true,
          onTap: onNext,
        ),
      ],
    );
  }
}
