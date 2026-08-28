import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/demo/demo_repository.dart';
import 'package:ibudaya/core/demo/demo_scenario.dart';

/// Unit tests for the booking mutation on LocalDemoRepository.
void main() {
  late LocalDemoRepository repo;

  final seed = DemoScenario(
    meta: DemoMeta(label: 'Test Seed', generatedAt: DateTime.utc(2026, 8, 1)),
    user: DemoUser(
      id: 'test-id',
      displayName: 'Ibu Clara',
      greetingName: 'Ibu Clara',
      role: 'Anggota IbuDaya',
      phone: '+62 812',
      city: 'Jakarta',
      joinedAt: DateTime.utc(2024, 1, 1),
    ),
    impact: const DemoImpactMetrics(
      totalEnergyUsedKwh: 100,
      energySharedKwh: 20,
      co2AvoidedKg: 50,
      arisanGroupSize: 10,
      monthlySavingIdr: 200000,
      solarSharePct: 40,
    ),
    creditInputs: const DemoCreditInputs(
      energyUsageConsistency: 0.8,
      paymentHistory: 0.8,
      businessActivity: 0.8,
      communityParticipation: 0.8,
    ),
    loanParams: const DemoLoanParams(
      minIdr: 500000,
      maxDemoFinancingIdr: 2000000,
      flatMonthlyRatePct: 2.0,
      eligibleScoreThreshold: 65,
    ),
    arisanSummary: const DemoArisanSummary(
      groupName: 'Grup Test',
      memberCount: 10,
      myContributionStatus: 'lunas',
      myTurnPosition: 2,
    ),
    arisan: DemoArisanGroup(
      id: 'ars-001',
      name: 'Arisan Energi Melati',
      myContributionStatus: 'lunas',
      myTurnPosition: 4,
      nextTurnDate: DateTime(2026, 10, 1),
      members: const [],
      rotation: const [],
      ledger: const [],
    ),
    quota: const DemoEnergyQuota(
      availableKwh: 12.0,
      neededKwh: 5.0,
      myTurnSlotLabel: 'Jumat, 10.00–12.00',
    ),
    offers: const [],
    threads: const [],
    solarDaySummary: const DemoSolarDaySummary(
      capacityPct: 80,
      statusLabel: 'Aktif',
    ),
    roofScan: const DemoRoofScan(
      suitability: 'sangatBaik',
      estimatedPotentialAreaM2: 50,
      roofOrientationLabel: 'Timur',
      sunExposurePotentialLabel: 'Tinggi',
      verificationNotice: 'Estimasi awal.',
      tip: 'Bagus.',
    ),
    solarDay: const DemoSolarDay(
      capacityPct: 80,
      recommendedSlotId: 'slot-1',
      recommendationReason: 'Cerah',
      slots: [
        DemoSolarSlot(id: 'slot-1', label: '08.00–10.00', availability: 'open'),
        DemoSolarSlot(id: 'slot-2', label: '10.00–12.00', availability: 'full'),
      ],
      appliances: [
        DemoAppliance(kind: 'oven', name: 'Oven', approxPowerKw: 1.5),
      ],
    ),
  );

  setUp(() {
    repo = LocalDemoRepository(seed);
  });

  group('LocalDemoRepository — bookings', () {
    test('starts empty', () {
      expect(repo.bookings, isEmpty);
    });

    test('addBooking appends to the list', () {
      final booking = DemoSolarBooking(
        id: 'BKG-001',
        applianceKind: 'oven',
        applianceName: 'Oven',
        slotId: 'slot-1',
        slotLabel: '08.00–10.00',
        date: DateTime(2026, 8, 1),
        createdAt: DateTime.now(),
      );
      repo.addBooking(booking);
      expect(repo.bookings.length, 1);
      expect(repo.bookings.first.id, 'BKG-001');
    });

    test('bookings list is unmodifiable', () {
      expect(
        () => (repo.bookings as List).add(
          DemoSolarBooking(
            id: 'x',
            applianceKind: 'x',
            applianceName: 'x',
            slotId: 'x',
            slotLabel: 'x',
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('reset clears bookings', () {
      repo.addBooking(
        DemoSolarBooking(
          id: 'BKG-001',
          applianceKind: 'oven',
          applianceName: 'Oven',
          slotId: 'slot-1',
          slotLabel: '08.00–10.00',
          date: DateTime(2026, 8, 1),
          createdAt: DateTime.now(),
        ),
      );
      expect(repo.bookings.length, 1);
      repo.reset();
      expect(repo.bookings, isEmpty);
    });

    test('can add multiple bookings', () {
      for (int i = 0; i < 3; i++) {
        repo.addBooking(
          DemoSolarBooking(
            id: 'BKG-00$i',
            applianceKind: 'oven',
            applianceName: 'Oven',
            slotId: 'slot-1',
            slotLabel: '08.00–10.00',
            date: DateTime(2026, 8, 1),
            createdAt: DateTime.now(),
          ),
        );
      }
      expect(repo.bookings.length, 3);
    });
  });
}
