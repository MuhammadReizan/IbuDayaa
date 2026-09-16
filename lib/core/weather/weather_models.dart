import 'package:flutter/foundation.dart';

/// One BMKG 3-hourly forecast point for a single administrative region
/// (an `adm4` code, e.g. "16.71.05.1001"). Field meanings follow BMKG's
/// public forecast API: https://data.bmkg.go.id/prakiraan-cuaca/
///
/// IMPLEMENTATION STATUS: IMPLEMENTED as a data holder. Whether a given
/// instance holds real BMKG data or a test fixture depends entirely on who
/// constructs it — this class makes no claim either way.
@immutable
class WeatherPoint {
  const WeatherPoint({
    required this.time,
    required this.cloudCoverPct,
    required this.condition,
    required this.temperatureC,
  });

  /// Local time this forecast point applies to.
  final DateTime time;

  /// BMKG "tcc" (total cloud cover), 0-100.
  final int cloudCoverPct;

  /// BMKG's own Indonesian weather description, e.g. "Cerah Berawan".
  final String condition;

  final double temperatureC;
}

/// The single best solar-production window found for one day, derived from
/// a list of [WeatherPoint]s by a fixed, transparent rule
/// (`deriveSolarOutlook` in weather_service.dart).
///
/// This is NOT a machine-learning or AI prediction — see CLAUDE.md
/// "No AI claims". It is arithmetic (lowest cloud cover in daylight hours)
/// over a real BMKG forecast. The UI must always show [source] next to it.
@immutable
class SolarOutlook {
  const SolarOutlook({
    required this.windowStart,
    required this.windowEnd,
    required this.cloudCoverPct,
    required this.condition,
    required this.generatedAt,
  });

  final DateTime windowStart;
  final DateTime windowEnd;
  final int cloudCoverPct;
  final String condition;

  /// When this outlook was computed (not when BMKG produced the forecast).
  final DateTime generatedAt;

  /// Attribution BMKG's terms of use require next to any figure derived
  /// from their data.
  static const source = 'BMKG (data.bmkg.go.id)';
}
