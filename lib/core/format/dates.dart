import 'package:intl/intl.dart';

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

/// `"10 Mei"` — locale-free.
String formatShortDate(DateTime d) => '${d.day} ${_idMonthsShort[d.month - 1]}';

/// `"Jum, 10 Mei"` — locale-free.
String formatShortDayDate(DateTime d) =>
    '${_idDaysShort[d.weekday - 1]}, ${formatShortDate(d)}';

/// A booking / arisan time-slot label, e.g. `"10.00–12.00"` (dots, en-dash).
String slotLabel(int startHour, int endHour) {
  String hh(int h) => '${h.toString().padLeft(2, '0')}.00';
  return '${hh(startHour)}–${hh(endHour)}';
}

/// Short relative-time label for inbox / notification rows: same calendar day →
/// `"08.40"`, yesterday → `"Kemarin"`, else `"d/M"`. [now] is the scenario's
/// "today" (see `demoNowProvider`) so Demo Mode reads consistently offline.
String relativeTimeLabel(DateTime t, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(t.year, t.month, t.day);
  final int days = today.difference(that).inDays;
  if (days <= 0) {
    return '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';
  }
  if (days == 1) return 'Kemarin';
  return '${t.day}/${t.month}';
}
