import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/app/app.dart';
import 'package:ibudaya/core/demo/demo_providers.dart';
import 'package:ibudaya/core/demo/demo_scenario.dart';

/// Minimal but valid fake scenario for widget tests.
/// All required fields added to match the extended DemoScenario constructor.
DemoScenario _fakeScenario() => DemoScenario(
  meta: DemoMeta(
    label: 'Skenario Demo — Ibu Clara',
    generatedAt: DateTime(2026, 8, 1),
  ),
  user: DemoUser(
    id: 'IDB-2404-1287',
    displayName: 'Ibu Clara',
    greetingName: 'Ibu Clara',
    role: 'Anggota IbuDaya',
    phone: '+62 812-3456-7890',
    city: 'Palembang',
    joinedAt: DateTime(2024, 4, 1),
  ),
  // Minimal impact values (docs/DATA_MODEL.md §3.3).
  impact: const DemoImpactMetrics(
    totalEnergyUsedKwh: 128,
    energySharedKwh: 32,
    co2AvoidedKg: 96,
    arisanGroupSize: 12,
    monthlySavingIdr: 245000,
    solarSharePct: 45,
  ),
  // Canonical Ibu Clara credit inputs (docs/DATA_MODEL.md §4.1).
  creditInputs: const DemoCreditInputs(
    energyUsageConsistency: 0.857,
    paymentHistory: 0.80,
    businessActivity: 0.90,
    communityParticipation: 0.667,
  ),
  loanParams: const DemoLoanParams(
    minIdr: 500000,
    maxDemoFinancingIdr: 2000000,
    flatMonthlyRatePct: 2.0,
    eligibleScoreThreshold: 65,
  ),
  // Arisan summary — DEMO_SIMULATION.
  arisanSummary: const DemoArisanSummary(
    groupName: 'Arisan Energi Melati',
    memberCount: 12,
    myContributionStatus: 'lunas',
    myTurnPosition: 4,
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
  // Solar Hub day summary — DEMO_SIMULATION (docs/DATA_MODEL.md §3.7).
  solarDaySummary: const DemoSolarDaySummary(
    capacityPct: 86,
    statusLabel: 'Aktif',
  ),
  // Roof scan — DEMO_SIMULATION.
  roofScan: const DemoRoofScan(
    suitability: 'sangatBaik',
    estimatedPotentialAreaM2: 60.0,
    roofOrientationLabel: 'Menghadap timur–barat',
    sunExposurePotentialLabel: 'Tinggi',
    verificationNotice:
        'Ini estimasi awal. Perlu verifikasi teknis di lokasi sebelum pemasangan.',
    tip:
        'Atap dengan orientasi timur–barat memiliki paparan sinar matahari yang optimal.',
  ),
  // Solar day — DEMO_SIMULATION.
  solarDay: const DemoSolarDay(
    capacityPct: 86,
    recommendedSlotId: 'slot-2',
    recommendationReason: 'Cuaca cerah dan energi Solar Hub cukup tersedia.',
    slots: [
      DemoSolarSlot(id: 'slot-1', label: '08.00–10.00', availability: 'open'),
      DemoSolarSlot(id: 'slot-2', label: '10.00–12.00', availability: 'open'),
    ],
    appliances: [DemoAppliance(kind: 'oven', name: 'Oven', approxPowerKw: 1.5)],
  ),
);

void main() {
  testWidgets('app boots through the splash gate into the 4-tab shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoScenarioProvider.overrideWith((ref) => _fakeScenario()),
        ],
        child: const IbuDayaApp(),
      ),
    );

    // Splash resolves and redirects to Home on the next frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    // Bottom-nav shell is present with the four destinations.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Solar Hub'), findsWidgets);
    expect(find.text('Pesan'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);

    // Home screen renders the greeting from the (overridden) scenario.
    // SC-01: greeting uses "Hi, Ibu Clara 👋" format.
    expect(find.textContaining('Ibu Clara'), findsWidgets);
  });

  testWidgets('can switch to the Profil tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoScenarioProvider.overrideWith((ref) => _fakeScenario()),
        ],
        child: const IbuDayaApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Ibu Clara'), findsWidgets);
  });
}
