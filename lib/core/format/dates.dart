import 'package:intl/intl.dart';

/// Indonesian date + time-slot formatting. See docs/DESIGN_SYSTEM.md §9.
///
/// `initializeDateFormatting('id_ID')` must have run (done in bootstrap) before
/// these are used.
final DateFormat _dayDate = DateFormat('EEEE, d MMM', 'id_ID');
final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');

/// `"Jumat, 10 Mei"`.
String formatDayDate(DateTime date) => _dayDate.format(date);

/// `"Mei 2024"`.
String formatMonthYear(DateTime date) => _monthYear.format(date);

/// A booking / arisan time-slot label, e.g. `"10.00–12.00"` (dots, en-dash).
String slotLabel(int startHour, int endHour) {
  String hh(int h) => '${h.toString().padLeft(2, '0')}.00';
  return '${hh(startHour)}–${hh(endHour)}';
}
