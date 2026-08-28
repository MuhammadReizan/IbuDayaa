import 'package:intl/intl.dart';

/// Energy (kWh) and percentage formatting. See docs/DESIGN_SYSTEM.md §9.
final NumberFormat _kwh = NumberFormat('0.#', 'id_ID');

/// `12` -> `"12 kWh"`, `3.2` -> `"3,2 kWh"` (comma decimal, id_ID).
String formatKwh(num value) => '${_kwh.format(value)} kWh';

/// Bare kWh number without the unit suffix (`3.2` -> `"3,2"`).
String formatKwhValue(num value) => _kwh.format(value);

/// `45` -> `"45%"`. Whole numbers only unless [decimals] is raised.
String formatPercent(num value, {int decimals = 0}) {
  final String pattern = decimals > 0 ? '0.${'#' * decimals}' : '0';
  return '${NumberFormat(pattern, 'id_ID').format(value)}%';
}
