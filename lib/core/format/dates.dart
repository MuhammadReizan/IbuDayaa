import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

/// Indonesian date + time-slot formatting. See docs/DESIGN_SYSTEM.md §9.
///
/// The [DateFormat]-based helpers need `initializeDateFormatting('id_ID')`
/// (done in bootstrap). The manual helpers below have no locale dependency and
/// are safe in widget tests that pump the app directly.
final DateFormat _dayDate = DateFormat('EEEE, d MMM', 'id_ID');
final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');

/// `"Jumat, 10 Mei"` (needs locale data initialised).
String formatDayDate(DateTime date) => _dayDate.format(date);

/// `"Mei 2024"` (needs locale data initialised).
String formatMonthYear(DateTime date) => _monthYear.format(date);

const List<String> _idMonthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];
const List<String> _idDaysShort = [
  'Sen',
  'Sel',
  'Rab',
  'Kam',
  'Jum',
  'Sab',
  'Min',
];

const List<String> _idMonthsLong = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// `"September 2026"` — supports optional [l10n].
String monthYearLabel(DateTime d, {AppLocalizations? l10n}) =>
    '${l10n != null ? l10n.monthLong(d.month) : _idMonthsLong[d.month - 1]} ${d.year}';

/// `"Sep 2026"` — supports optional [l10n].
String shortMonthYear(DateTime d, {AppLocalizations? l10n}) =>
    '${l10n != null ? l10n.monthShort(d.month) : _idMonthsShort[d.month - 1]} ${d.year}';

/// `"Sep"` — chart axis labels, supports optional [l10n].
String monthAbbr(DateTime d, {AppLocalizations? l10n}) =>
    l10n != null ? l10n.monthShort(d.month) : _idMonthsShort[d.month - 1];

/// `"11 September 2026"` — supports optional [l10n].
String formatLongDate(DateTime d, {AppLocalizations? l10n}) =>
    '${d.day} ${l10n != null ? l10n.monthLong(d.month) : _idMonthsLong[d.month - 1]} ${d.year}';

/// `"08.40"`.
String formatClock(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

/// `"11 Sep 2026, 08.40"` — supports optional [l10n].
String formatDateTime(DateTime d, {AppLocalizations? l10n}) =>
    '${formatShortDate(d, l10n: l10n)} ${d.year}, ${formatClock(d)}';

/// `"10 Mei"` — supports optional [l10n].
String formatShortDate(DateTime d, {AppLocalizations? l10n}) =>
    '${d.day} ${l10n != null ? l10n.monthShort(d.month) : _idMonthsShort[d.month - 1]}';

/// `"Jum, 10 Mei"` — supports optional [l10n].
String formatShortDayDate(DateTime d, {AppLocalizations? l10n}) =>
    '${l10n != null ? l10n.dayShort(d.weekday) : _idDaysShort[d.weekday - 1]}, ${formatShortDate(d, l10n: l10n)}';

/// A booking / arisan time-slot label, e.g. `"10.00–12.00"` (dots, en-dash).
String slotLabel(int startHour, int endHour) {
  String hh(int h) => '${h.toString().padLeft(2, '0')}.00';
  return '${hh(startHour)}–${hh(endHour)}';
}

/// Short relative-time label for inbox / notification rows: same calendar day →
/// `"08.40"`, yesterday → `"Kemarin"`, else `"d/M"`. [now] is the scenario's
/// "today" (see `demoNowProvider`) so Demo Mode reads consistently offline.
String relativeTimeLabel(DateTime t, DateTime now, {AppLocalizations? l10n}) {
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(t.year, t.month, t.day);
  final int days = today.difference(that).inDays;
  if (days <= 0) {
    return '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';
  }
  if (days == 1) return l10n?.dateYesterday ?? 'Kemarin';
  return '${t.day}/${t.month}';
}
