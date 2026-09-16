import 'dart:convert';

import 'package:http/http.dart' as http;

import 'weather_models.dart';
import 'weather_service.dart';

/// Real client for BMKG's public forecast API
/// (https://data.bmkg.go.id/prakiraan-cuaca/, base URL
/// `https://api.bmkg.go.id/publik/prakiraan-cuaca`). No API key; BMKG rate-
/// limits it to 60 requests/minute/IP and asks that anything built on it
/// credit BMKG as the source — see [SolarOutlook.source] and show it
/// wherever this data appears on screen.
///
/// IMPLEMENTATION STATUS: IMPLEMENTED — a real network call, not a demo
/// simulation (docs/ASSUMPTIONS_AND_RISKS.md honesty hierarchy). It reads
/// genuine BMKG data but can still fail offline or on a flaky connection;
/// every caller must treat [WeatherUnavailableException] as routine and
/// hide the feature rather than guess a number.
///
/// VERIFIED against a live response on 2026-09-17 (`GET
/// $_base?adm4=16.71.05.1001`, a real kelurahan in Kota Palembang — Ilir
/// Timur Satu / Delapan-belas Ilir): the response shape and every field
/// this class reads (`data[0].cuaca` as a list of daily lists, `tcc`,
/// `weather_desc`, `t`, `local_datetime`) match exactly what's parsed
/// below. An unknown/empty `adm4` returns HTTP 404 with a JSON error body,
/// which the status-code check below already turns into
/// [WeatherUnavailableException].
class BmkgWeatherService implements WeatherService {
  BmkgWeatherService({
    http.Client? client,
    this.timeout = const Duration(seconds: 6),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  static const _base = 'https://api.bmkg.go.id/publik/prakiraan-cuaca';

  @override
  Future<List<WeatherPoint>> fetchForecast(String adm4Code) async {
    final uri = Uri.parse('$_base?adm4=$adm4Code');
    final http.Response resp;
    try {
      resp = await _client.get(uri).timeout(timeout);
    } catch (e) {
      throw WeatherUnavailableException('Network error: $e');
    }
    if (resp.statusCode != 200) {
      throw WeatherUnavailableException(
        'BMKG returned HTTP ${resp.statusCode}',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(resp.body);
    } catch (e) {
      throw WeatherUnavailableException('Could not decode response: $e');
    }
    if (decoded is! Map<String, dynamic>) {
      throw WeatherUnavailableException('Unexpected response shape');
    }

    try {
      return _parse(decoded);
    } catch (e) {
      throw WeatherUnavailableException('Could not read forecast: $e');
    }
  }

  /// BMKG nests the 3-hourly points under `data[0].cuaca`, a list of one
  /// inner list per forecast day.
  List<WeatherPoint> _parse(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! List || data.isEmpty) return const [];
    final first = data.first;
    if (first is! Map<String, dynamic>) return const [];
    final cuaca = first['cuaca'];
    if (cuaca is! List) return const [];

    final points = <WeatherPoint>[];
    for (final day in cuaca) {
      if (day is! List) continue;
      for (final entry in day) {
        if (entry is! Map<String, dynamic>) continue;
        final localTime = entry['local_datetime'];
        if (localTime is! String) continue;
        DateTime time;
        try {
          time = DateTime.parse(localTime.replaceFirst(' ', 'T'));
        } catch (_) {
          continue;
        }
        points.add(
          WeatherPoint(
            time: time,
            cloudCoverPct: _cloudCoverPct(entry),
            condition: (entry['weather_desc'] as String?) ?? '-',
            temperatureC: (entry['t'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
    }
    return points;
  }

  /// `tcc` is BMKG's real field for total cloud cover (confirmed against a
  /// live response — see the class doc above). The extra keys are kept as a
  /// defensive fallback only, in case BMKG changes the schema later.
  int _cloudCoverPct(Map<String, dynamic> entry) {
    for (final key in const ['tcc', 'cc', 'cloud_cover']) {
      final v = entry[key];
      if (v is num) return v.round().clamp(0, 100);
    }
    // Unknown cloud cover reads as "fully overcast" so the picker never
    // recommends a window it has no real signal for.
    return 100;
  }
}
