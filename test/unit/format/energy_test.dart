import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/format/energy.dart';

void main() {
  group('formatKwh', () {
    test('whole numbers have no decimal', () {
      expect(formatKwh(12), '12 kWh');
    });

    test('fractional values use a comma decimal (id_ID)', () {
      expect(formatKwh(3.2), '3,2 kWh');
    });

    test('bare value helper drops the unit', () {
      expect(formatKwhValue(3.2), '3,2');
    });
  });

  group('formatPercent', () {
    test('whole percent by default', () {
      expect(formatPercent(45), '45%');
      expect(formatPercent(86), '86%');
    });
  });
}
