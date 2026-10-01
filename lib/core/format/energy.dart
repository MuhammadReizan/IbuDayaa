import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

/// Energy (kWh) and percentage formatting. See docs/DESIGN_SYSTEM.md §9.
final NumberFormat _kwhId = NumberFormat('0.#', 'id_ID');
final NumberFormat _kwhEn = NumberFormat('0.#', 'en_US');

NumberFormat get _kwh => AppLocalizations.current.isEn ? _kwhEn : _kwhId;

/// `12` -> `"12 kWh"`, `3.2` -> `"3,2 kWh"` (comma decimal, id_ID).
String formatKwh(num value) => '${_kwh.format(value)} kWh';

/// Bare kWh number without the unit suffix (`3.2` -> `"3,2"`).
String formatKwhValue(num value) => _kwh.format(value);

/// `45` -> `"45%"`. Whole numbers only unless [decimals] is raised.
String formatPercent(num value, {int decimals = 0}) {
  final String pattern = decimals > 0 ? '0.${'#' * decimals}' : '0';
  final locale = AppLocalizations.current.isEn ? 'en_US' : 'id_ID';
  return '${NumberFormat(pattern, locale).format(value)}%';
}
