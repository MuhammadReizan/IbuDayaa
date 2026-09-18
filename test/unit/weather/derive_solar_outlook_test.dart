import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/weather/weather_models.dart';
import 'package:ibudaya/core/weather/weather_service.dart';

WeatherPoint _point(
  DateTime time,
  int cloudCoverPct, {
  String condition = 'Cerah',
}) => WeatherPoint(
  time: time,
  cloudCoverPct: cloudCoverPct,
  condition: condition,
  temperatureC: 30,
);

void main() {
  final today = DateTime(2026, 9, 16);

  group('deriveSolarOutlook', () {
    test('picks the point with the lowest cloud cover inside 10.00–14.00', () {
      final points = [
        _point(DateTime(2026, 9, 16, 9), 5, condition: 'Cerah'),
        _point(DateTime(2026, 9, 16, 10), 20, condition: 'Cerah Berawan'),
        _point(DateTime(2026, 9, 16, 13), 10, condition: 'Cerah'),
        _point(DateTime(2026, 9, 16, 15), 0, condition: 'Cerah'),
      ];

      final outlook = deriveSolarOutlook(points, today);

      expect(outlook, isNotNull);
      expect(outlook!.windowStart, DateTime(2026, 9, 16, 13));
      // Capped at 14.00, not a full 3-hour window (would be 16.00).
      expect(outlook.windowEnd, DateTime(2026, 9, 16, 14));
      expect(outlook.cloudCoverPct, 10);
      expect(outlook.condition, 'Cerah');
    });

    test('never picks a point outside 10.00–14.00, however clear', () {
      final points = [
        _point(DateTime(2026, 9, 16, 6), 0), // clearest of all, too early
        _point(DateTime(2026, 9, 16, 9), 0), // still before the window
        _point(DateTime(2026, 9, 16, 15), 0), // clearest, but too late
        _point(DateTime(2026, 9, 16, 18), 0),
        _point(DateTime(2026, 9, 16, 11), 50), // only point inside 10–14
      ];

      final outlook = deriveSolarOutlook(points, today);

      expect(outlook, isNotNull);
      expect(outlook!.windowStart, DateTime(2026, 9, 16, 11));
      expect(outlook.cloudCoverPct, 50);
    });

    test('the window never extends past 14.00', () {
      // A 3-hour window from 12.00 would run to 15.00 — must clamp to 14.00.
      final points = [_point(DateTime(2026, 9, 16, 12), 10)];

      final outlook = deriveSolarOutlook(points, today);

      expect(outlook, isNotNull);
      expect(outlook!.windowStart, DateTime(2026, 9, 16, 12));
      expect(outlook.windowEnd, DateTime(2026, 9, 16, 14));
    });

    test('ignores points from other days', () {
      final points = [
        _point(DateTime(2026, 9, 17, 12), 0),
        _point(DateTime(2026, 9, 15, 12), 0),
      ];

      expect(deriveSolarOutlook(points, today), isNull);
    });

    test('returns null when nothing falls inside 10.00–14.00 that day', () {
      final points = [
        _point(DateTime(2026, 9, 16, 6), 0),
        _point(DateTime(2026, 9, 16, 9), 0),
        _point(DateTime(2026, 9, 16, 15), 0),
      ];

      expect(deriveSolarOutlook(points, today), isNull);
    });

    test('returns null with no points at all', () {
      expect(deriveSolarOutlook(const [], today), isNull);
    });

    test('ties go to the earliest window (stable sort)', () {
      final points = [
        _point(DateTime(2026, 9, 16, 13), 30, condition: 'A'),
        _point(DateTime(2026, 9, 16, 10), 30, condition: 'B'),
      ];

      final outlook = deriveSolarOutlook(points, today);

      expect(outlook!.windowStart, DateTime(2026, 9, 16, 10));
      expect(outlook.condition, 'B');
    });

    test(
      'rain and panel heat lower the score, so a clearer but rainy point loses',
      () {
        final points = [
          _point(DateTime(2026, 9, 16, 10), 20, condition: 'Hujan Ringan'),
          _point(DateTime(2026, 9, 16, 13), 40, condition: 'Berawan'),
        ];

        final outlook = deriveSolarOutlook(points, today)!;

        // 10.00: 100 − 16 − 25 = 59; 13.00: 100 − 32 = 68.
        expect(outlook.windowStart, DateTime(2026, 9, 16, 13));
        expect(outlook.productionScore, 68);
      },
    );

    test('hot air derates the panels above 30°C', () {
      final hot = WeatherPoint(
        time: DateTime(2026, 9, 16, 11),
        cloudCoverPct: 0,
        condition: 'Cerah',
        temperatureC: 40,
      );
      // 100 − 0.4 × 10 = 96.
      expect(productionScoreOf(hot), 96);
    });
  });
}
