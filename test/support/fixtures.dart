import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/data/app_data.dart';
import 'package:ibudaya/core/data/app_data_controller.dart';
import 'package:ibudaya/core/data/app_store.dart';
import 'package:ibudaya/core/data/models.dart';

UserProfile testProfile({double tariff = 1000}) => UserProfile(
  name: 'Ibu Sari',
  businessName: 'Katering Sari',
  city: 'Palembang',
  joinedAt: DateTime(2025, 1, 1),
  tariffIdrPerKwh: tariff,
);

Bill testBill({
  required String id,
  required int monthsAgo,
  required double kwh,
  int? totalIdr,
  double tariff = 1000,
}) {
  final now = DateTime.now();
  return Bill(
    id: id,
    periodMonth: DateTime(now.year, now.month - monthsAgo),
    kwh: kwh,
    totalIdr: totalIdr ?? (kwh * tariff).round(),
    recordedAt: now,
  );
}

Appliance testAppliance({
  required String id,
  required String name,
  required double watts,
  double hoursPerDay = 2,
  int daysPerWeek = 7,
}) => Appliance(
  id: id,
  name: name,
  watts: watts,
  hoursPerDay: hoursPerDay,
  daysPerWeek: daysPerWeek,
);

/// A container backed by an in-memory store, seeded with [data].
ProviderContainer testContainer([AppData data = AppData.empty]) {
  final container = ProviderContainer(
    overrides: [appStoreProvider.overrideWithValue(MemoryAppStore(data))],
  );
  addTearDown(container.dispose);
  return container;
}

/// Waits for [appDataProvider] to finish its initial load.
Future<AppData> loadData(ProviderContainer container) =>
    container.read(appDataProvider.future);
