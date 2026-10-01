import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

/// Indonesian date + time-slot formatting. See docs/DESIGN_SYSTEM.md §9.
///
/// The [DateFormat]-based helpers need `initializeDateFormatting('id_ID')`
/// (done in bootstrap). The manual helpers below have no locale dependency and
/// are safe in widget tests that pump the app directly.
final DateFormat _dayDateId = DateFormat('EEEE, d MMM', 'id_ID');
final DateFormat _monthYearId = DateFormat('MMMM yyyy', 'id_ID');
final DateFormat _dayDateEn = DateFormat('EEEE, d MMM', 'en_US');
final DateFormat _monthYearEn = DateFormat('MMMM yyyy', 'en_US');

bool get _english => AppLocalizations.current.isEn;

/// `"Jumat, 10 Mei"` / `"Friday, 10 May"` (needs locale data initialised).
String formatDayDate(DateTime date) =>
    (_english ? _dayDateEn : _dayDateId).format(date);

/// `"Mei 2024"` / `"May 2024"` (needs locale data initialised).
String formatMonthYear(DateTime date) =>
    (_english ? _monthYearEn : _monthYearId).format(date);

/// `"September 2026"` — supports optional [l10n].
String monthYearLabel(DateTime d, {AppLocalizations? l10n}) =>
    '${(l10n ?? AppLocalizations.current).monthLong(d.month)} ${d.year}';

/// `"Sep 2026"` — supports optional [l10n].
String shortMonthYear(DateTime d, {AppLocalizations? l10n}) =>
    '${(l10n ?? AppLocalizations.current).monthShort(d.month)} ${d.year}';

/// `"Sep"` — chart axis labels, supports optional [l10n].
String monthAbbr(DateTime d, {AppLocalizations? l10n}) =>
    (l10n ?? AppLocalizations.current).monthShort(d.month);

/// `"11 September 2026"` — supports optional [l10n].
String formatLongDate(DateTime d, {AppLocalizations? l10n}) =>
    '${d.day} ${(l10n ?? AppLocalizations.current).monthLong(d.month)} ${d.year}';

/// `"08.40"`.
String formatClock(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

/// `"11 Sep 2026, 08.40"` — supports optional [l10n].
String formatDateTime(DateTime d, {AppLocalizations? l10n}) =>
    '${formatShortDate(d, l10n: l10n)} ${d.year}, ${formatClock(d)}';

/// `"10 Mei"` — supports optional [l10n].
String formatShortDate(DateTime d, {AppLocalizations? l10n}) =>
    '${d.day} ${(l10n ?? AppLocalizations.current).monthShort(d.month)}';

/// `"Jum, 10 Mei"` — supports optional [l10n].
String formatShortDayDate(DateTime d, {AppLocalizations? l10n}) =>
    '${(l10n ?? AppLocalizations.current).dayShort(d.weekday)}, ${formatShortDate(d, l10n: l10n)}';

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
  if (days == 1) return (l10n ?? AppLocalizations.current).dateYesterday;
  return '${t.day}/${t.month}';
}
