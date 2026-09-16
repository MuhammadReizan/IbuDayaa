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
    test('picks the daylight point with the lowest cloud cover', () {
      final points = [
        _point(DateTime(2026, 9, 16, 6), 80, condition: 'Berawan'),
        _point(DateTime(2026, 9, 16, 9), 20, condition: 'Cerah Berawan'),
        _point(DateTime(2026, 9, 16, 12), 10, condition: 'Cerah'),
        _point(DateTime(2026, 9, 16, 15), 60, condition: 'Berawan'),
      ];

      final outlook = deriveSolarOutlook(points, today);

      expect(outlook, isNotNull);
      expect(outlook!.windowStart, DateTime(2026, 9, 16, 12));
      expect(outlook.windowEnd, DateTime(2026, 9, 16, 15));
      expect(outlook.cloudCoverPct, 10);
      expect(outlook.condition, 'Cerah');
    });

    test('ignores points outside 06:00–18:00', () {
      final points = [
        _point(DateTime(2026, 9, 16, 3), 0), // clearest, but before dawn
        _point(DateTime(2026, 9, 16, 21), 5), // clearest, but after dusk
        _point(DateTime(2026, 9, 16, 9), 50),
      ];

      final outlook = deriveSolarOutlook(points, today);

      expect(outlook, isNotNull);
      expect(outlook!.windowStart, DateTime(2026, 9, 16, 9));
      expect(outlook.cloudCoverPct, 50);
    });

    test('ignores points from other days', () {
      final points = [
        _point(DateTime(2026, 9, 17, 12), 0),
        _point(DateTime(2026, 9, 15, 12), 0),
      ];

      expect(deriveSolarOutlook(points, today), isNull);
    });

    test('returns null with no daylight points at all', () {
      expect(deriveSolarOutlook(const [], today), isNull);
    });

    test('ties go to the earliest window (stable sort)', () {
      final points = [
        _point(DateTime(2026, 9, 16, 14), 30, condition: 'A'),
        _point(DateTime(2026, 9, 16, 8), 30, condition: 'B'),
      ];

      final outlook = deriveSolarOutlook(points, today);

      expect(outlook!.windowStart, DateTime(2026, 9, 16, 8));
      expect(outlook.condition, 'B');
    });
  });
}
