import 'package:flutter/material.dart';

import '../invoice.dart';
import '../theme.dart';

/// The title block above the stamp. Before the press it carries the
/// instruction; once the stamp has landed it reports the outcome, and on the
/// finished page adds an inline way back out.
class StampHeader extends StatelessWidget {
  const StampHeader({
    super.key,
    required this.landed,
    required this.confirmed,
    required this.voided,
    required this.label,
    required this.date,
    required this.ink,
    required this.onUndo,
  });

  final bool landed;
  final bool confirmed;
  final bool voided;
  final StampLabel label;
  final DateTime date;
  final Color ink;

  /// On the finished page this is a way out, not a rewind: it behaves like
  /// Next invoice.
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
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
          child: landed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        voided
                            ? 'Voided on ${date.longLine}'
                            : '${label.past} on ${date.longLine}',
                        style: Type.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (confirmed) ...[
                      const Text(' · ', style: Type.body),
                      GestureDetector(
                        onTap: onUndo,
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
}
