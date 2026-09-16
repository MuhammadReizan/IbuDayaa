import 'weather_models.dart';

/// Thrown when a live forecast could not be fetched or parsed — no network,
/// a timeout, an unexpected BMKG response shape, and so on.
///
/// Callers must treat this as routine, not a bug: the honesty hierarchy in
/// docs/ASSUMPTIONS_AND_RISKS.md forbids showing a fabricated number when
/// the real one is unavailable, so the correct response is to hide the
/// weather panel, never to fall back to a guessed value.
class WeatherUnavailableException implements Exception {
  const WeatherUnavailableException(this.message);
  final String message;

  @override
  String toString() => 'WeatherUnavailableException: $message';
}

/// A source of real weather forecasts, keyed by BMKG's `adm4` region code.
///
/// IMPLEMENTATION STATUS: this interface itself is just a contract. See
/// `BmkgWeatherService` (IMPLEMENTED, a real HTTP client) for the production
/// implementation used by the app.
abstract interface class WeatherService {
  /// Today's and tomorrow's 3-hourly forecast for [adm4Code].
  /// Throws [WeatherUnavailableException] on any failure.
  Future<List<WeatherPoint>> fetchForecast(String adm4Code);
}

/// Picks the daylight (06:00–18:00) forecast point with the lowest cloud
/// cover on [date] and reports it as a 3-hour production window.
///
/// This is a fixed threshold rule over real forecast data — it is NOT a
/// machine-learning or AI model (see CLAUDE.md "No AI claims"), and it
/// makes no claim to be more accurate than the raw BMKG forecast it reads.
/// It is deliberately simple so it can be explained in one sentence, the
/// same bar the credit-scoring engine holds itself to
/// (`RuleBasedCreditScoringEngine`).
///
/// Returns null when [points] has no daylight entry for [date].
SolarOutlook? deriveSolarOutlook(List<WeatherPoint> points, DateTime date) {
  final daylight = points.where((p) {
    final t = p.time;
    return t.year == date.year &&
        t.month == date.month &&
        t.day == date.day &&
        t.hour >= 6 &&
        t.hour < 18;
  }).toList();
  if (daylight.isEmpty) return null;

  // Explicit min-by instead of sort+first: ties must deterministically go
  // to the earliest window, and List.sort is not guaranteed stable.
  var best = daylight.first;
  for (final p in daylight.skip(1)) {
    if (p.cloudCoverPct < best.cloudCoverPct ||
        (p.cloudCoverPct == best.cloudCoverPct && p.time.isBefore(best.time))) {
      best = p;
    }
  }

  return SolarOutlook(
    windowStart: best.time,
    windowEnd: best.time.add(const Duration(hours: 3)),
    cloudCoverPct: best.cloudCoverPct,
    condition: best.condition,
    generatedAt: DateTime.now(),
  );
}
