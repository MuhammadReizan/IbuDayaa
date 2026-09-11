/// Reads the numbers that matter off OCR text from a PLN receipt.
///
/// Handles the two receipts Indonesian micro-businesses actually hold:
/// - **Pascabayar** payment receipts (STAND METER, BL/TH, RP TAG PLN, TOTAL BAYAR)
///   and PLN Mobile e-bills ("Pemakaian 120 kWh", "Total Tagihan").
/// - **Prabayar** token receipts (JML KWH, RP BAYAR, STROOM/TOKEN).
///
/// OCR is imperfect, so every field is optional and the user always confirms
/// or corrects the values before anything is saved.
library;

import 'package:flutter/foundation.dart';

import '../models/energy.dart';

@immutable
class ParsedReceipt {
  const ParsedReceipt({
    required this.rawText,
    this.kind,
    this.kwh,
    this.totalIdr,
    this.periodMonth,
    this.customerId,
  });

  final String rawText;
  final EnergyKind? kind;
  final double? kwh;
  final int? totalIdr;
  final DateTime? periodMonth;
  final String? customerId;

  bool get foundAnything => kwh != null || totalIdr != null;
  bool get isComplete => kwh != null && totalIdr != null;
}

/// One recognised line and where it sits on the photo.
@immutable
class OcrLine {
  const OcrLine({
    required this.text,
    required this.top,
    required this.bottom,
    required this.left,
  });

  final String text;
  final double top;
  final double bottom;
  final double left;

  double get centerY => (top + bottom) / 2;
  double get height => bottom - top;
}

/// Rebuilds receipt rows from OCR lines. Receipts print a label on the left
/// and its value on the right; OCR often returns those as separate blocks, so
/// "TOTAL BAYAR :" and "Rp 177.500" would end up on different lines and the
/// parser could not pair them. Lines whose vertical centres align are joined
/// left-to-right into one row.
String layoutOcrLines(List<OcrLine> lines) {
  if (lines.isEmpty) return '';
  final sorted = [...lines]..sort((a, b) => a.centerY.compareTo(b.centerY));
  final rows = <List<OcrLine>>[];
  for (final line in sorted) {
    final row = rows.isEmpty ? null : rows.last;
    if (row != null) {
      final rowCenter =
          row.fold<double>(0, (s, l) => s + l.centerY) / row.length;
      final tolerance = line.height.clamp(1.0, double.infinity) * 0.6;
      if ((line.centerY - rowCenter).abs() <= tolerance) {
        row.add(line);
        continue;
      }
    }
    rows.add([line]);
  }
  return rows
      .map(
        (r) => (r..sort((a, b) => a.left.compareTo(b.left)))
            .map((l) => l.text)
            .join(' '),
      )
      .join('\n');
}

ParsedReceipt parsePlnReceipt(String text) {
  final t = _normalize(text);
  final kind = _detectKind(t);

  final double? kwh = kind == EnergyKind.token
      ? (_tokenKwh(t) ?? _genericKwh(t))
      : (_explicitUsage(t) ?? _standMeterUsage(t) ?? _genericKwh(t));

  return ParsedReceipt(
    rawText: text,
    kind: kind,
    kwh: kwh,
    totalIdr: _total(t),
    periodMonth: _period(t),
    customerId: _customerId(t),
  );
}

// ---------------------------------------------------------------------------

String _normalize(String text) {
  var t = text.toUpperCase().replaceAll('\r', '');
  // OCR reads 0 as O and 1 as I next to digits ("2O2.5OO"). Repeat because a
  // run of letters only becomes digit-adjacent once its neighbour is fixed.
  final confusable = RegExp(r'(?<=[0-9][.,]?)[OI]|[OI](?=[.,]?[0-9])');
  for (int i = 0; i < 4 && confusable.hasMatch(t); i++) {
    t = t.replaceAllMapped(confusable, (m) => m[0] == 'O' ? '0' : '1');
  }
  t = t.replaceAll(RegExp(r'RP\s*\.'), 'RP ');
  t = t.replaceAll(RegExp(r'[ \t]+'), ' ');
  return t;
}

EnergyKind? _detectKind(String t) {
  if (RegExp(r'STROOM|TOKEN|(?:JML|JUMLAH)\s*KWH').hasMatch(t)) {
    return EnergyKind.token;
  }
  if (RegExp(
    r'STAND\s*METER|BL\s*/?\s*TH|RP\s*TAG|TAGIHAN|PEMAKAIAN',
  ).hasMatch(t)) {
    return EnergyKind.postpaid;
  }
  return null;
}

double? _tokenKwh(String t) {
  final m = RegExp(
    r'(?:JML|JUMLAH)\s*KWH[^0-9\n]{0,6}([0-9][0-9.,]*)',
  ).firstMatch(t);
  return _plausibleKwh(m?.group(1));
}

double? _explicitUsage(String t) {
  final m = RegExp(
    r'PEMAKAIAN[^0-9\n]{0,15}([0-9][0-9.,]*)\s*KWH',
  ).firstMatch(t);
  return _plausibleKwh(m?.group(1));
}

double? _standMeterUsage(String t) {
  final m = RegExp(
    r'STAND\s*METER[^0-9\n]{0,6}([0-9]{4,9})\s*[-–~]\s*([0-9]{4,9})',
  ).firstMatch(t);
  if (m == null) return null;
  final start = int.tryParse(m.group(1)!);
  final end = int.tryParse(m.group(2)!);
  if (start == null || end == null) return null;
  final diff = end - start;
  return (diff > 0 && diff < 20000) ? diff.toDouble() : null;
}

double? _genericKwh(String t) {
  for (final m in RegExp(r'([0-9][0-9.,]*)\s*KWH').allMatches(t)) {
    final v = _plausibleKwh(m.group(1));
    if (v != null) return v;
  }
  return null;
}

double? _plausibleKwh(String? s) {
  if (s == null) return null;
  final v = parseIndonesianNumber(s);
  return (v != null && v > 0 && v < 20000) ? v : null;
}

int? _total(String t) {
  const labels = [
    r'TOTAL\s*BAYAR',
    r'TOTAL\s*TAGIHAN',
    r'JUMLAH\s*BAYAR',
    r'RP\s*BAYAR',
    r'TOTAL',
    r'RP\s*TAG(?:IHAN)?(?:\s*PLN)?',
    r'TAGIHAN',
  ];
  for (final label in labels) {
    for (final m in RegExp(
      '$label[^0-9\\n]{0,15}([0-9][0-9.,]*)',
    ).allMatches(t)) {
      // "TOTAL KWH : 136,4" is energy, not money.
      final after = t.substring(m.end, (m.end + 5).clamp(0, t.length));
      if (after.trimLeft().startsWith('KWH')) continue;
      final v = _plausibleRupiah(m.group(1));
      if (v != null) return v;
    }
  }
  // Last resort: the largest amount written next to "RP".
  int? best;
  for (final m in RegExp(r'RP\s*([0-9][0-9.,]*)').allMatches(t)) {
    final v = _plausibleRupiah(m.group(1));
    if (v != null && (best == null || v > best)) best = v;
  }
  return best;
}

int? _plausibleRupiah(String? s) {
  if (s == null) return null;
  final cleaned = s
      .replaceAll(RegExp(r'[.,]00$'), '')
      .replaceAll(RegExp(r'[^0-9]'), '');
  final v = int.tryParse(cleaned);
  return (v != null && v >= 1000 && v <= 100000000) ? v : null;
}

const Map<String, int> _monthAbbr = {
  'JAN': 1,
  'FEB': 2,
  'MAR': 3,
  'APR': 4,
  'MEI': 5,
  'MAY': 5,
  'JUN': 6,
  'JUL': 7,
  'AGU': 8,
  'AGS': 8,
  'AUG': 8,
  'SEP': 9,
  'OKT': 10,
  'OCT': 10,
  'NOV': 11,
  'DES': 12,
  'DEC': 12,
};

const Map<String, int> _monthFull = {
  'JANUARI': 1,
  'FEBRUARI': 2,
  'MARET': 3,
  'APRIL': 4,
  'MEI': 5,
  'JUNI': 6,
  'JULI': 7,
  'AGUSTUS': 8,
  'SEPTEMBER': 9,
  'OKTOBER': 10,
  'NOVEMBER': 11,
  'DESEMBER': 12,
};

int _year(String y) {
  final v = int.parse(y);
  return v < 100 ? 2000 + v : v;
}

DateTime? _period(String t) {
  final bl = RegExp(
    r'BL\s*/?\s*TH[^A-Z0-9\n]{0,4}([A-Z]{3})[^0-9\n]{0,2}([0-9]{2,4})',
  ).firstMatch(t);
  if (bl != null) {
    final month = _monthAbbr[bl.group(1)];
    if (month != null) return DateTime(_year(bl.group(2)!), month);
  }

  final full = RegExp(
    '(${_monthFull.keys.join('|')})\\s+([0-9]{4})',
  ).firstMatch(t);
  if (full != null) {
    return DateTime(int.parse(full.group(2)!), _monthFull[full.group(1)]!);
  }

  final date = RegExp(
    r'\b([0-3]?[0-9])[-/.]([01]?[0-9])[-/.]((?:20)?[0-9]{2})\b',
  ).firstMatch(t);
  if (date != null) {
    final month = int.parse(date.group(2)!);
    if (month >= 1 && month <= 12) {
      return DateTime(_year(date.group(3)!), month);
    }
  }
  return null;
}

String? _customerId(String t) => RegExp(
  r'ID\s*PEL(?:ANGGAN)?[^0-9\n]{0,4}([0-9]{11,12})',
).firstMatch(t)?.group(1);

/// `136,4` → 136.4 · `1.234` → 1234 · `1.234,5` → 1234.5 · `136.4` → 136.4.
double? parseIndonesianNumber(String input) {
  var s = input.trim().replaceAll(RegExp(r'[.,]+$'), '');
  if (s.isEmpty) return null;
  if (s.contains(',') && s.contains('.')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (s.contains(',')) {
    s = s.replaceAll(',', '.');
  } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) {
    s = s.replaceAll('.', '');
  }
  return double.tryParse(s);
}
