import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'invoice.dart';

/// Builds the invoice as a PDF and hands it to the browser or OS to save. On
/// the web this is a download; elsewhere it is the share sheet. [stampPng] is
/// the on-screen mark, rasterised, so the ink matches what was printed.
Future<void> downloadInvoicePdf({required Uint8List? stampPng}) async {
  final doc = pw.Document(title: 'Invoice ${Invoice.id}');
  const muted = PdfColor.fromInt(0xFF8A8A93);
  const text = PdfColor.fromInt(0xFF16161A);
  const hairline = PdfColor.fromInt(0xFFE6E6E9);

  pw.Widget field(String label, String value) => pw.RichText(
    text: pw.TextSpan(
      style: const pw.TextStyle(fontSize: 9, color: muted),
      children: [
        pw.TextSpan(text: '$label: '),
        pw.TextSpan(
          text: value,
          style: const pw.TextStyle(color: text),
        ),
      ],
    ),
  );

  pw.Widget row(List<String> cells, {bool faint = false}) => pw.Row(
    children: [
      for (final (i, c) in cells.indexed)
        pw.Expanded(
          flex: [4, 1, 2, 2][i],
          child: pw.Text(
            c,
            textAlign: i == 3 ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: 9,
              color: faint ? const PdfColor.fromInt(0xFFBFBFC6) : muted,
            ),
          ),
        ),
    ],
  );

  final stamp = stampPng == null
      ? pw.SizedBox()
      : pw.Image(pw.MemoryImage(stampPng), width: 190);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Invoice',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                width: 16,
                height: 16,
                decoration: pw.BoxDecoration(
                  color: text,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          pw.Text(
            Invoice.studio,
            style: const pw.TextStyle(fontSize: 9, color: muted),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    field('ABN', Invoice.abn),
                    field('Email', Invoice.email),
                    field('Web', Invoice.web),
                    field('Address', Invoice.address),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    field('Invoice to', Invoice.billTo),
                    field('Invoice ID', Invoice.id),
                    field('Date of issue', Invoice.issued),
                    field('Payment due', Invoice.due),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Divider(color: hairline, thickness: 0.8),
          pw.SizedBox(height: 10),
          pw.Text(
            'Description of services',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          row(['Description', 'Quantity', 'Unit price', 'Total'], faint: true),
          pw.SizedBox(height: 4),
          for (final item in Invoice.items) ...[
            row([item.description, item.quantity, item.unitPrice, item.total]),
            pw.SizedBox(height: 4),
          ],
          pw.SizedBox(height: 6),
          pw.Divider(color: hairline, thickness: 0.8),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'Total amount due:  ',
                style: const pw.TextStyle(fontSize: 9, color: muted),
              ),
              pw.Text(
                Invoice.total,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 36),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bank details for payment:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Bank: ${Invoice.bank}\nBSB: ${Invoice.bsb}\n'
                      'Account number: ${Invoice.account}\n'
                      'Name: ${Invoice.studio}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: muted,
                        lineSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              stamp,
            ],
          ),
          pw.Spacer(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Thank you for your business.',
                style: const pw.TextStyle(fontSize: 9, color: muted),
              ),
              pw.Text(
                Invoice.web,
                style: const pw.TextStyle(fontSize: 9, color: muted),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'invoice-${Invoice.id}.pdf',
  );
}
