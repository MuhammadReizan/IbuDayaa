import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/demo/demo_providers.dart';
import 'package:ibudaya/core/demo/demo_scenario.dart';

/// Shared, self-contained demo seed for unit/widget tests. Mirrors the shape of
/// `assets/demo/scenario_happy_path.json` closely enough for domain tests
/// without loading the real asset bundle.
DemoScenario demoSeedScenario() => DemoScenario(
  meta: DemoMeta(
    label: 'Skenario Demo — Ibu Clara',
    generatedAt: DateTime(2026, 8, 1, 9),
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
  impact: const DemoImpactMetrics(
    totalEnergyUsedKwh: 128,
    energySharedKwh: 32,
    co2AvoidedKg: 96,
    arisanGroupSize: 12,
    monthlySavingIdr: 245000,
    solarSharePct: 45,
  ),
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
  arisanSummary: const DemoArisanSummary(
    groupName: 'Arisan Energi Melati',
    memberCount: 12,
    myContributionStatus: 'lunas',
    myTurnPosition: 4,
  ),
  solarDaySummary: const DemoSolarDaySummary(
    capacityPct: 86,
    statusLabel: 'Aktif',
  ),
  energyInsight: const DemoEnergyInsight(
    spikeDetected: true,
    spikeWindowLabel: '18.00–21.00',
    addedMonthlyCostIdr: 45200,
    mainInsight: 'Pemakaian daya malam hari cukup tinggi.',
    contributors: [
      DemoApplianceCost(applianceKind: 'oven', name: 'Oven', costIdr: 18500),
    ],
  ),
  roofScan: const DemoRoofScan(
    suitability: 'sangatBaik',
    estimatedPotentialAreaM2: 60,
    roofOrientationLabel: 'Menghadap timur–barat',
    sunExposurePotentialLabel: 'Tinggi',
    verificationNotice:
        'Ini estimasi awal. Perlu verifikasi teknis di lokasi sebelum pemasangan.',
    tip: 'Atap dengan orientasi timur–barat optimal untuk Solar Hub komunitas.',
  ),
  solarDay: const DemoSolarDay(
    capacityPct: 86,
    recommendedSlotId: 'slot-2',
    recommendationReason: 'Cuaca cerah dan energi Solar Hub cukup tersedia.',
    slots: [
      DemoSolarSlot(id: 'slot-1', label: '08.00–10.00', availability: 'open'),
      DemoSolarSlot(id: 'slot-2', label: '10.00–12.00', availability: 'open'),
      DemoSolarSlot(id: 'slot-3', label: '13.00–15.00', availability: 'full'),
    ],
    appliances: [
      DemoAppliance(kind: 'oven', name: 'Oven', approxPowerKw: 1.5),
      DemoAppliance(kind: 'blender', name: 'Blender', approxPowerKw: 0.35),
    ],
  ),
  arisan: DemoArisanGroup(
    id: 'ars-001',
    name: 'Arisan Energi Melati',
    myContributionStatus: 'lunas',
    myTurnPosition: 4,
    nextTurnDate: DateTime(2026, 10, 1),
    members: const [
      DemoArisanMember(
        id: 'IDB-2404-1287',
        name: 'Ibu Clara',
        isCurrentUser: true,
      ),
      DemoArisanMember(id: 'm-002', name: 'Siti Rahma', isCurrentUser: false),
      DemoArisanMember(id: 'm-003', name: 'Ibu Lina', isCurrentUser: false),
    ],
    rotation: [
      DemoRotationSlot(
        date: DateTime(2026, 9, 1),
        memberId: 'm-003',
        memberName: 'Ibu Lina',
      ),
      DemoRotationSlot(
        date: DateTime(2026, 10, 1),
        memberId: 'IDB-2404-1287',
        memberName: 'Ibu Clara',
      ),
    ],
    ledger: [
      DemoLedgerEntry(
        id: 'LED-001',
        type: 'contribution',
        memberId: 'IDB-2404-1287',
        memberName: 'Ibu Clara',
        amountIdr: 150000,
        timestamp: DateTime(2026, 8, 1, 10),
        status: 'settled',
      ),
    ],
  ),
  quota: const DemoEnergyQuota(
    availableKwh: 12.0,
    neededKwh: 5.0,
    myTurnSlotLabel: 'Jumat, 10.00–12.00',
  ),
  offers: [
    DemoQuotaOffer(
      id: 'off-001',
      ownerMemberId: 'm-002',
      ownerName: 'Siti Rahma',
      amountKwh: 5.0,
      slotLabel: 'Sabtu, 08.00–10.00',
      note: 'Saya punya sisa kuota hari Sabtu.',
      status: 'open',
      createdAt: DateTime(2026, 7, 30, 14),
    ),
    DemoQuotaOffer(
      id: 'off-002',
      ownerMemberId: 'm-003',
      ownerName: 'Ibu Lina',
      amountKwh: 3.0,
      slotLabel: 'Minggu, 10.00–12.00',
      status: 'open',
      createdAt: DateTime(2026, 7, 31, 9),
    ),
    // Owned by the current user — used to assert takeOffer rejects own offers.
    DemoQuotaOffer(
      id: 'off-own',
      ownerMemberId: 'IDB-2404-1287',
      ownerName: 'Ibu Clara',
      amountKwh: 2.0,
      slotLabel: 'Sabtu, 13.00–15.00',
      status: 'open',
      createdAt: DateTime(2026, 7, 31, 12),
    ),
  ],
  threads: [
    DemoMessageThread(
      id: 'th-001',
      kind: 'group',
      title: 'Arisan Energi Melati',
      lastPreview:
          'Ibu Lina: Terima kasih semua anggota sudah lunas bulan ini!',
      lastAt: DateTime(2026, 8, 1, 10, 30),
      unreadCount: 2,
      messages: const [],
    ),
    DemoMessageThread(
      id: 'th-002',
      kind: 'admin',
      title: 'Solar Hub Admin',
      lastPreview: 'Admin: Slot Solar Hub Sabtu tersedia, silakan booking.',
      lastAt: DateTime(2026, 7, 31, 16),
      unreadCount: 1,
      messages: const [],
    ),
    DemoMessageThread(
      id: 'th-003',
      kind: 'system',
      title: 'Tips IbuDaya',
      lastPreview: 'Hemat energi: gunakan alat listrik di jam pagi Solar Hub.',
      lastAt: DateTime(2026, 7, 29, 7),
      unreadCount: 0,
      messages: const [],
    ),
  ],
);

/// A [ProviderContainer] with the demo scenario seeded synchronously.
ProviderContainer newDemoContainer({DemoScenario? scenario}) {
  final container = ProviderContainer(
    overrides: [
      demoScenarioProvider.overrideWith(
        (ref) => scenario ?? demoSeedScenario(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}
