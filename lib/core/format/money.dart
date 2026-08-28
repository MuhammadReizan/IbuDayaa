import 'package:intl/intl.dart';

/// Indonesian rupiah formatting. See docs/DESIGN_SYSTEM.md §9.
///
/// Always route currency through here — never format inline in a widget.
final NumberFormat _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// `2000000` -> `"Rp 2.000.000"`. Negatives -> `"-Rp 2.000.000"`.
String formatRupiah(num value) {
  if (value < 0) return '-${_rupiah.format(value.abs())}';
  return _rupiah.format(value);
}

/// `"≈ Rp 373.333"` — used for simulated / rounded figures (CR-14).
String formatRupiahApprox(num value) => '≈ ${formatRupiah(value)}';
