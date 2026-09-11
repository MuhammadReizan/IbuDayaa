/// Typed reads from a database row. Tolerant of missing values so an older
/// row written before a column existed still loads.
library;

String rStr(Map<String, dynamic> r, String k) => (r[k] as String?) ?? '';

String? rStrN(Map<String, dynamic> r, String k) {
  final v = r[k];
  return v is String && v.isNotEmpty ? v : null;
}

int rInt(Map<String, dynamic> r, String k, [int fallback = 0]) =>
    (r[k] as num?)?.toInt() ?? fallback;

int? rIntN(Map<String, dynamic> r, String k) => (r[k] as num?)?.toInt();

double rDbl(Map<String, dynamic> r, String k, [double fallback = 0]) =>
    (r[k] as num?)?.toDouble() ?? fallback;

double? rDblN(Map<String, dynamic> r, String k) => (r[k] as num?)?.toDouble();

DateTime rDate(Map<String, dynamic> r, String k) =>
    DateTime.tryParse((r[k] as String?) ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0);

DateTime? rDateN(Map<String, dynamic> r, String k) =>
    DateTime.tryParse((r[k] as String?) ?? '');

/// Postgres `timestamptz`.
String ts(DateTime d) => d.toIso8601String();

/// Postgres `date` — no time, no zone.
String dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime monthOf(DateTime d) => DateTime(d.year, d.month);

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int monthsBetween(DateTime from, DateTime to) =>
    (to.year - from.year) * 12 + (to.month - from.month);
