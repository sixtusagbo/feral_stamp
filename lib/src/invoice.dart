import 'package:flutter/material.dart';

/// The label rolled onto the stamp head. Mirrors the reference's chip row.
enum StampLabel {
  paid('Paid', 'PAID'),
  received('Received', 'RECEIVED'),
  approved('Approved', 'APPROVED'),
  due('Due', 'DUE');

  const StampLabel(this.chip, this.head);

  /// Sentence-case text for the selector chip.
  final String chip;

  /// Letterspaced caps printed on the stamp itself.
  final String head;

  String get action => 'Mark as ${chip.toLowerCase()}';
  String get past => 'Marked as ${chip.toLowerCase()}';
}

class LineItem {
  const LineItem(this.description, this.quantity, this.unitPrice, this.total);

  final String description;
  final String quantity;
  final String unitPrice;
  final String total;
}

/// The invoice from the reference demo, reproduced field for field.
class Invoice {
  const Invoice();

  static const studio = 'FeralUI Studio';
  static const abn = '51 824 753 556';
  static const email = 'hello@feralui.dev';
  static const web = 'feralui.dev';
  static const address = '12 Paper Lane, Fitzroy VIC 3065';

  static const billTo = 'Northwind Pty Ltd';
  static const id = 'FUI-0067';
  static const issued = '01/09/2026';
  static const due = '15/09/2026';

  static const items = <LineItem>[
    LineItem('Component design', '12.00', r'$85/hour', r'$1,020.00'),
    LineItem('Motion prototypes', '4.50', r'$85/hour', r'$382.50'),
    LineItem('Figma handoff', '2.00', r'$85/hour', r'$170.00'),
  ];

  static const total = r'$1,572.50';

  static const bank = 'Northbank';
  static const bsb = '000-000';
  static const account = '1234 5678';
}

const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

const _monthsLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// The three wheels: days 1-31, JAN-DEC, 2021-2031.
class Wheels {
  const Wheels._();

  static final days = List.generate(31, (i) => '${i + 1}');
  static const months = _months;
  static final years = List.generate(11, (i) => '${2021 + i}');
}

extension StampDate on DateTime {
  /// `15 SEP 2026` — the form printed inside the stamp.
  String get stampLine => '$day ${_months[month - 1]} $year';

  /// `15 Sep 2026` — the compact form used in the toast.
  String get shortLine {
    final m = _months[month - 1];
    return '$day ${m[0]}${m.substring(1).toLowerCase()} $year';
  }

  /// `Tuesday, 15 September 2026` — the readout under the picker.
  String get longLine =>
      '${_weekdays[weekday - 1]}, $day ${_monthsLong[month - 1]} $year';
}

/// Clamps a day to the selected month so 31 FEB can never be stamped.
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// A tiny helper for the paper's drop shadow, reused by sheet and stamp.
List<BoxShadow> paperShadow(double lift) => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.13 * lift),
    blurRadius: 34 * lift,
    spreadRadius: -6,
    offset: Offset(0, 20 * lift),
  ),
];
