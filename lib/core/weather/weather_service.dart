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

/// The production-hour window candidates are drawn from — the sun's most
/// productive stretch, not the full 06:00–18:00 daylight span. Named
/// constants so the window is easy to find and re-test if it ever changes.
const int kProductionWindowStartHour = 10;
const int kProductionWindowEndHour = 14;

/// Above this air temperature panels lose output. ASSUMPTION (typical
/// crystalline-silicon coefficient of about 0.4 % per °C), stated on screen.
const double kPanelDerateAboveC = 30;
const double kPanelDeratePctPerC = 0.4;

/// Penalty when BMKG forecasts rain or thunder for the point.
const int kRainPenalty = 25;

bool isRainy(String condition) {
  final c = condition.toLowerCase();
  return c.contains('hujan') || c.contains('petir');
}

/// Production score 0–100 for one forecast point. Fixed, explainable
/// arithmetic — not a trained model:
///   100 − 0.8 × cloud cover %      (cloud cover as a sunlight proxy)
///   − 25 when BMKG forecasts rain or thunder
///   − 0.4 × (°C above 30)          (panel heat derating)
int productionScoreOf(WeatherPoint p) {
  var score = 100 - 0.8 * p.cloudCoverPct;
  if (isRainy(p.condition)) score -= kRainPenalty;
  final over = p.temperatureC - kPanelDerateAboveC;
  if (over > 0) score -= over * kPanelDeratePctPerC;
  return score.clamp(0, 100).round();
}

/// Scores every forecast point inside the production window (10.00–14.00)
/// on [date] with [productionScoreOf] and reports the best one as a
/// production window capped at [kProductionWindowEndHour].
///
/// This is a fixed rule over real forecast data — it is NOT a
/// machine-learning or AI model (see CLAUDE.md "No AI claims"), and it
/// makes no claim to be more accurate than the raw BMKG forecast it reads.
/// Every input to the score is shown next to the result, so it can be
/// explained in one sentence — the same bar the credit-scoring engine holds
/// itself to (`RuleBasedCreditScoringEngine`).
///
/// Returns null when [points] has no entry inside the production window for
/// [date] — BMKG's 3-hourly points don't always land inside every window,
/// and the panel simply hides itself rather than guessing.
SolarOutlook? deriveSolarOutlook(List<WeatherPoint> points, DateTime date) {
  final productive = points.where((p) {
    final t = p.time;
    return t.year == date.year &&
        t.month == date.month &&
        t.day == date.day &&
        t.hour >= kProductionWindowStartHour &&
        t.hour < kProductionWindowEndHour;
  }).toList();
  if (productive.isEmpty) return null;

  // Explicit max-by instead of sort+first: ties must deterministically go
  // to the earliest window, and List.sort is not guaranteed stable.
  var best = productive.first;
  var bestScore = productionScoreOf(best);
  for (final p in productive.skip(1)) {
    final score = productionScoreOf(p);
    if (score > bestScore ||
        (score == bestScore && p.time.isBefore(best.time))) {
      best = p;
      bestScore = score;
    }
  }

  final cap = DateTime(
    date.year,
    date.month,
    date.day,
    kProductionWindowEndHour,
  );
  final uncappedEnd = best.time.add(const Duration(hours: 3));
  final windowEnd = uncappedEnd.isAfter(cap) ? cap : uncappedEnd;

  return SolarOutlook(
    windowStart: best.time,
    windowEnd: windowEnd,
    cloudCoverPct: best.cloudCoverPct,
    condition: best.condition,
    temperatureC: best.temperatureC,
    productionScore: bestScore,
    generatedAt: DateTime.now(),
  );
}
