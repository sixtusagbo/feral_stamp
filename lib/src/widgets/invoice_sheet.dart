import 'package:flutter/material.dart';

import '../invoice.dart';
import '../theme.dart';
import 'stamp_mark.dart';

/// The page that gets stamped. Laid out at a fixed size so the mark can be
/// positioned against the paper rather than against the viewport.
class InvoiceSheet extends StatelessWidget {
  const InvoiceSheet({
    super.key,
    required this.headText,
    required this.date,
    required this.color,
    this.bleed = 0,
  });

  final String headText;
  final DateTime date;
  final Color color;
  final double bleed;

  static const width = 380.0;

  /// Wraps the printed mark so it can be rasterised for the PDF.
  static final stampKey = GlobalKey();

  /// Nominal height. The paper grows if a larger text scale needs the room,
  /// so the layout never hard-fails on an unexpected font.
  static const height = 408.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: height),
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 18),
      decoration: BoxDecoration(color: Tone.paper, boxShadow: paperShadow(1)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Invoice',
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Tone.text,
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Tone.text,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const Text(Invoice.studio, style: _micro),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Field('ABN', Invoice.abn),
                    _Field('Email', Invoice.email),
                    _Field('Web', Invoice.web),
                    _Field('Address', Invoice.address),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Field('Invoice to', Invoice.billTo),
                    const _Field('Invoice ID', Invoice.id),
                    const _Field('Date of issue', Invoice.issued),
                    const _Field('Payment due', Invoice.due),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _Rule(),
          const SizedBox(height: 8),
          const Text('Description of services', style: _heading),
          const SizedBox(height: 7),
          const _Row(
            LineItem('Description', 'Quantity', 'Unit price', 'Total'),
            faint: true,
          ),
          const SizedBox(height: 2),
          for (final item in Invoice.items) _Row(item),
          const SizedBox(height: 6),
          const _Rule(),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Flexible(
                child: Text(
                  'Total amount due:  ',
                  style: _micro,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Text(
                Invoice.total,
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Tone.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bank details for payment:', style: _heading),
                    SizedBox(height: 3),
                    Text(
                      'Bank: ${Invoice.bank}\n'
                      'BSB: ${Invoice.bsb}\n'
                      'Account number: ${Invoice.account}\n'
                      'Name: ${Invoice.studio}',
                      style: _micro,
                    ),
                  ],
                ),
              ),
              // Keeps its natural size on a normal page and scales down
              // rather than crushing the bank block on a narrow one.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  // Padded so the rotated mark is not clipped when captured.
                  child: RepaintBoundary(
                    key: stampKey,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: StampMark(
                        label: headText,
                        date: date.stampLine,
                        color: color,
                        bleed: bleed,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Thank you for your business.',
                  style: _micro,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  Invoice.web,
                  style: _micro,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _micro = TextStyle(
  fontFamily: 'Helvetica Neue',
  fontSize: 7.5,
  color: Tone.muted,
  height: 1.5,
);

const _heading = TextStyle(
  fontFamily: 'Helvetica Neue',
  fontSize: 8.5,
  fontWeight: FontWeight.w600,
  color: Tone.text,
);

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.5),
      child: RichText(
        text: TextSpan(
          style: _micro,
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(color: Tone.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.item, {this.faint = false});

  final LineItem item;

  /// The column headings are set lighter than the rows beneath them.
  final bool faint;

  @override
  Widget build(BuildContext context) {
    final style = faint
        ? _micro.copyWith(color: const Color(0xFFBFBFC6))
        : _micro;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item.description,
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              item.quantity,
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.unitPrice,
              style: style,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(item.total, textAlign: TextAlign.right, style: _micro),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: Tone.hairline);
}
