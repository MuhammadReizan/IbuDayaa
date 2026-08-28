import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../../core/demo/demo_scenario.dart';

/// Provides the current user's booked solar slots from the demo session.
final solarBookingsProvider = Provider<List<DemoSolarBooking>>((ref) {
  return ref.watch(demoRepositoryProvider).bookings;
});

/// Exposes the current simulated Solar Hub day status and capacity.
final solarDayProvider = Provider<DemoSolarDay>((ref) {
  return ref.watch(demoRepositoryProvider).current.solarDay;
});

/// Exposes the roof scan simulation data.
final roofScanProvider = Provider<DemoRoofScan>((ref) {
  return ref.watch(demoRepositoryProvider).current.roofScan;
});
