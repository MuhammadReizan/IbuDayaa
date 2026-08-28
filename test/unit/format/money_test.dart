import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/format/money.dart';

void main() {
  group('formatRupiah', () {
    test('formats with id_ID thousands separators', () {
      expect(formatRupiah(2000000), 'Rp 2.000.000');
      expect(formatRupiah(245000), 'Rp 245.000');
      expect(formatRupiah(0), 'Rp 0');
    });

    test('handles negative values', () {
      expect(formatRupiah(-45200), '-Rp 45.200');
    });

    test('approx variant prefixes with the almost-equal sign', () {
      expect(formatRupiahApprox(373333), '≈ Rp 373.333');
    });
  });
}
