import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import 'bmkg_weather_service.dart';
import 'weather_models.dart';
import 'weather_service.dart';

/// The [WeatherService] the app talks to. Overriding this in a
/// `ProviderScope` (tests, or a future offline/demo mode) swaps in a fake
/// without touching any screen.
final weatherServiceProvider = Provider<WeatherService>(
  (ref) => BmkgWeatherService(),
);

/// Today's best solar-production window for a hub's configured BMKG region
/// code ([adm4Code]) — null if no code is configured, the fetch failed, or
/// BMKG has no daylight forecast point for today.
///
/// Deliberately collapses [WeatherUnavailableException] (and any other
/// failure) into `null` rather than an error state: a hub with no live
/// forecast should look like a hub with no weather panel, never a broken
/// screen. Nothing else in the app depends on this succeeding
/// (docs/ASSUMPTIONS_AND_RISKS.md RT-05 — the offline experience must not
/// depend on a network call).
final solarOutlookProvider = FutureProvider.family<SolarOutlook?, String>((
  ref,
  adm4Code,
) async {
  final code = adm4Code.trim();
  if (code.isEmpty) return null;
  final service = ref.watch(weatherServiceProvider);
  final now = ref.read(clockProvider)();
  try {
    final points = await service.fetchForecast(code);
    return deriveSolarOutlook(points, now);
  } catch (_) {
    return null;
  }
});
