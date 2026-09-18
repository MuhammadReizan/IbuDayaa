import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _thousands = NumberFormat.decimalPattern('id_ID');

/// Digits only, shown as `177.500`.
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final digits = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final value = int.tryParse(digits);
    if (value == null) return old;
    final text = _thousands.format(value);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String thousands(num v) => _thousands.format(v.round());

int? parseDigits(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));

/// Accepts `136,4` or `136.4`.
final TextInputFormatter decimalInput = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9.,]'),
);

double? parseDecimal(String s) => parseIndonesianNumber(s);

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

/// `136.4` → `136,4`; `120.0` → `120`.
String decimalText(double v) {
  final s = v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1);
  return s.replaceAll('.', ',');
}
