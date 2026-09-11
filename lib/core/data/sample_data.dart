/// A ready-made set of records for trying the app out or running a
/// demonstration.
///
/// This is never loaded automatically: the user has to choose "Muat data
/// contoh" in Settings, and it replaces their own records. That keeps the
/// distinction honest — a fresh install shows empty states, and anything on
/// screen is either the user's or something they knowingly loaded.
library;

import 'app_data.dart';
import 'models.dart';

/// Builds the sample document, keeping [existing] profile details where the
/// user already has them so the demo still reads as theirs.
AppData buildSampleData(UserProfile? existing) {
  final now = DateTime.now();
  final profile =
      existing ??
      UserProfile(
        name: 'Ibu Clara',
        businessName: 'Katering Clara',
        city: 'Palembang',
        joinedAt: DateTime(now.year - 1, now.month),
        tariffIdrPerKwh: 1444.70,
      );

  DateTime month(int back) => DateTime(now.year, now.month - back);
  String id(String p, int i) => '$p-sample-$i';

  // Five months of bills with a deliberate spike in the latest one, so the
  // analysis and observation screens have something real to talk about.
  const kwhSeries = <double>[128, 112, 118, 109, 115];
  final bills = <Bill>[
    for (int i = 0; i < kwhSeries.length; i++)
      Bill(
        id: id('bill', i),
        periodMonth: month(i),
        kwh: kwhSeries[i],
        totalIdr: (kwhSeries[i] * profile.tariffIdrPerKwh).round(),
        recordedAt: month(i).add(const Duration(days: 3)),
      ),
  ];

  final appliances = <Appliance>[
    Appliance(
      id: id('app', 0),
      name: 'Oven',
      watts: 1500,
      hoursPerDay: 2,
      daysPerWeek: 6,
      kind: 'oven',
    ),
    Appliance(
      id: id('app', 1),
      name: 'Kulkas',
      watts: 150,
      hoursPerDay: 24,
      daysPerWeek: 7,
      kind: 'refrigerator',
    ),
    Appliance(
      id: id('app', 2),
      name: 'Blender',
      watts: 350,
      hoursPerDay: 1,
      daysPerWeek: 5,
      kind: 'blender',
    ),
  ];

  final sessions = <SolarSession>[
    for (int i = 0; i < 6; i++)
      SolarSession(
        id: id('ses', i),
        applianceName: i.isEven ? 'Oven' : 'Blender',
        date: now.subtract(Duration(days: 4 + i * 6)),
        slotLabel: i.isEven ? '10.00–12.00' : '13.00–15.00',
        kwh: i.isEven ? 3.0 : 0.7,
        recordedAt: now.subtract(Duration(days: 4 + i * 6)),
      ),
  ];

  final members = <ArisanMember>[
    ArisanMember(id: id('mbr', 0), name: profile.name, isMe: true),
    ArisanMember(id: id('mbr', 1), name: 'Siti Rahma'),
    ArisanMember(id: id('mbr', 2), name: 'Ibu Lina'),
    ArisanMember(id: id('mbr', 3), name: 'Ibu Putri'),
    ArisanMember(id: id('mbr', 4), name: 'Ibu Dewi'),
  ];

  final arisan = ArisanGroup(
    name: 'Arisan Energi Melati',
    contributionIdr: 150000,
    members: members,
    startedAt: DateTime(now.year, now.month - 4),
  );

  final ledger = <LedgerEntry>[
    for (int i = 0; i < 4; i++)
      LedgerEntry(
        id: id('led-c', i),
        type: 'contribution',
        memberId: members.first.id,
        memberName: members.first.name,
        amountIdr: 150000,
        at: month(i).add(const Duration(days: 5)),
      ),
    LedgerEntry(
      id: id('led-p', 0),
      type: 'payout',
      memberId: members[2].id,
      memberName: members[2].name,
      amountIdr: 750000,
      at: month(1).add(const Duration(days: 8)),
      note: 'Giliran Ibu Lina',
    ),
  ];

  final offers = <QuotaOffer>[
    QuotaOffer(
      id: id('off', 0),
      ownerId: members.first.id,
      ownerName: members.first.name,
      amountKwh: 2,
      slotLabel: 'Sabtu, 08.00–10.00',
      note: 'Sisa jatah minggu ini, silakan yang butuh.',
      status: 'taken',
      createdAt: now.subtract(const Duration(days: 12)),
      takenByName: 'Siti Rahma',
    ),
    QuotaOffer(
      id: id('off', 1),
      ownerId: members.first.id,
      ownerName: members.first.name,
      amountKwh: 3,
      slotLabel: 'Minggu, 10.00–12.00',
      status: 'open',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
  ];

  return AppData(
    profile: profile,
    bills: bills,
    appliances: appliances,
    sessions: sessions,
    arisan: arisan,
    ledger: ledger,
    offers: offers,
    calculations: [
      SavedCalculation(
        id: id('calc', 0),
        label: 'Rencana beli oven kedua',
        principalIdr: 2000000,
        tenorMonths: 6,
        monthlyRatePct: 2,
        savedAt: now.subtract(const Duration(days: 9)),
      ),
    ],
  );
}
