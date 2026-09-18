import '../../../features/credit_score/domain/credit_scoring_engine.dart';
import '../../db/ids.dart';
import '../../db/local_database.dart';
import '../../db/row.dart';
import '../../db/tables.dart';
import '../../models/models.dart';
import 'local_arisan_repository.dart';
import 'local_auth_repository.dart';
import 'local_loan_repository.dart';

/// A sample cooperative for trying the app or running the competition demo.
///
/// Local mode only, and only when the user taps "Coba dengan data contoh" on
/// the welcome screen — a fresh install never shows invented numbers. Every
/// account it creates is listed on that screen so nobody mistakes it for real.
class SampleSeeder {
  SampleSeeder(this.db, this.now, this.engine);

  final LocalDatabase db;
  final DateTime Function() now;
  final CreditScoringEngine engine;

  static const String pin = '147258';
  static const String adminPhone = '081200000001';
  static const String memberPhone = '081200000002';

  static const List<({String phone, String name, String business})> members = [
    (phone: memberPhone, name: 'Ibu Clara', business: 'Katering Clara'),
    (phone: '081200000003', name: 'Siti Rahma', business: 'Jahit Siti'),
    (phone: '081200000004', name: 'Ibu Lina', business: 'Kue Basah Lina'),
    (phone: '081200000005', name: 'Ibu Putri', business: 'Warung Putri'),
  ];

  bool get isSeeded =>
      db.first(Tbl.profiles, (r) => r['phone'] == '+6281200000001') != null;

  Future<void> seed() async {
    if (isSeeded) return;
    final t = now();
    DateTime monthsAgo(int n) => DateTime(t.year, t.month - n);
    final start = t.subtract(const Duration(days: 160));

    final auth = LocalAuthRepository(db, () => start);
    final admin = await auth.registerAdmin(
      phone: adminPhone,
      pin: pin,
      fullName: 'Ibu Ratna',
      city: 'Palembang',
      cooperativeName: 'Koperasi Energi Melati',
    );
    await db.update(Tbl.cooperatives, admin.cooperativeId, {
      // Shows the arisan payment screen how it looks once an admin has
      // filled this in, instead of the cash-only fallback.
      'arisan_bank_account': 'BCA 1234567890 a.n. Koperasi Energi Melati',
    });
    final coop = Cooperative.fromRow(
      db.find(Tbl.cooperatives, admin.cooperativeId)!,
    );

    final ids = <String>[];
    for (final m in members) {
      final p = await auth.registerMember(
        phone: m.phone,
        pin: pin,
        fullName: m.name,
        businessName: m.business,
        city: 'Palembang',
        inviteCode: coop.inviteCode,
      );
      ids.add(p.id);
    }
    final clara = ids[0];
    final siti = ids[1];
    final lina = ids[2];

    // Hub rating the admin would enter from the installation.
    final hub = SolarHub.fromRow(
      db.first(Tbl.solarHubs, (r) => r['cooperative_id'] == coop.id)!,
    );
    await db.update(Tbl.solarHubs, hub.id, {
      'name': 'Solar Hub Balai Melati',
      'location': 'Balai Warga RT 03, Palembang',
      'daily_capacity_kwh': 60,
    });
    final slots =
        db
            .select(Tbl.hubSlots, (r) => r['hub_id'] == hub.id)
            .map(HubSlot.fromRow)
            .toList()
          ..sort((a, b) => a.sort.compareTo(b.sort));

    Future<void> appliance(
      String userId,
      String name,
      String kind,
      double w,
      double h,
      int d,
    ) => db.insert(
      Tbl.appliances,
      Appliance(
        id: newId(),
        userId: userId,
        name: name,
        kind: kind,
        watts: w,
        hoursPerDay: h,
        daysPerWeek: d,
        createdAt: start,
      ).toRow(),
    );
    await appliance(clara, 'Oven', 'oven', 1500, 2, 6);
    await appliance(clara, 'Kulkas', 'refrigerator', 150, 24, 7);
    await appliance(clara, 'Blender', 'blender', 350, 1, 5);
    await appliance(siti, 'Mesin Jahit', 'sewingMachine', 100, 6, 6);

    // Sample usage is hub usage: each completed session is a booking plus
    // the record the hub creates automatically when the admin confirms it
    // (same as AppActions.setBookingStatus). Session counts are per 30-day
    // window, newest first.
    final slotId = slots[1].id;
    Future<void> hubSessions(
      String userId,
      String applianceName,
      double kwhPerSession,
      List<int> sessionsNewestFirst,
    ) async {
      for (int i = 0; i < sessionsNewestFirst.length; i++) {
        // Calendar months, so each month's total is what the app will sum.
        // The running month only has the days that have already passed.
        final first = DateTime(t.year, t.month - i);
        final days = i == 0
            ? t.day - 1
            : DateTime(t.year, t.month - i + 1, 0).day;
        if (days < 1) continue;
        final n = i == 0
            ? (sessionsNewestFirst[i] * days / 28).ceil()
            : sessionsNewestFirst[i];
        final step = days ~/ n < 1 ? 1 : days ~/ n;
        for (int j = 0; j < n; j++) {
          final day = dayOf(
            first.add(Duration(days: (j * step).clamp(0, days - 1))),
          );
          final bookingId = newId();
          await db.insert(
            Tbl.hubBookings,
            HubBooking(
              id: bookingId,
              hubId: hub.id,
              slotId: slotId,
              userId: userId,
              applianceName: applianceName,
              bookingDate: day,
              estKwh: kwhPerSession,
              status: BookingStatus.completed,
              createdAt: day,
            ).toRow(),
          );
          await db.insert(
            Tbl.energyRecords,
            EnergyRecord(
              id: newId(),
              userId: userId,
              kind: EnergyKind.token,
              periodMonth: monthOf(day),
              kwh: kwhPerSession,
              totalIdr: (kwhPerSession * 1444.70).round(),
              source: RecordSource.hub,
              bookingId: bookingId,
              createdAt: day.add(const Duration(hours: 14)),
            ).toRow(),
          );
        }
      }
    }

    // kWh per session = appliance watts × slot hours (the same estimate the
    // app uses for real sessions).
    await hubSessions(clara, 'Oven', 3.0, [8, 7, 8, 7, 8]);
    await hubSessions(clara, 'Blender', 0.7, [9, 8, 9, 8, 9]);
    await hubSessions(siti, 'Mesin Jahit', 0.6, [10, 10, 11, 9]);
    await hubSessions(lina, 'Mixer', 1.0, [8, 9, 8]);

    final arisan = LocalArisanRepository(db, () => monthsAgo(4));
    final group = await arisan.createGroup(
      admin: admin,
      name: 'Arisan Koperasi Melati',
      contributionIdr: 150000,
      startMonth: monthsAgo(4),
      memberIdsInTurnOrder: ids,
    );

    for (int back = 4; back >= 0; back--) {
      final month = monthsAgo(back);
      for (final id in ids) {
        final isCurrent = back == 0;
        if (isCurrent && id == lina) continue;
        final pending = isCurrent && id == siti;
        await db.insert(
          Tbl.arisanPayments,
          ArisanPayment(
            id: newId(),
            groupId: group.id,
            userId: id,
            type: PaymentType.contribution,
            amountIdr: 150000,
            periodMonth: month,
            status: pending ? PaymentStatus.pending : PaymentStatus.confirmed,
            reviewedBy: pending ? null : admin.id,
            reviewedAt: pending ? null : month.add(const Duration(days: 6)),
            createdAt: month.add(const Duration(days: 5)),
          ).toRow(),
        );
      }
      if (back > 0) {
        await db.insert(
          Tbl.arisanPayments,
          ArisanPayment(
            id: newId(),
            groupId: group.id,
            userId: ids[(4 - back) % ids.length],
            type: PaymentType.payout,
            amountIdr: 150000 * ids.length,
            periodMonth: month,
            status: PaymentStatus.confirmed,
            reviewedBy: admin.id,
            reviewedAt: month.add(const Duration(days: 20)),
            createdAt: month.add(const Duration(days: 20)),
          ).toRow(),
        );
      }
    }

    await db.insert(
      Tbl.quotaOffers,
      QuotaOffer(
        id: newId(),
        cooperativeId: coop.id,
        ownerId: clara,
        kind: QuotaKind.share,
        kwh: 2,
        slotNote: '',
        note: 'Sisa kuota minggu ini.',
        status: QuotaStatus.completed,
        counterpartyId: lina,
        createdAt: t.subtract(const Duration(days: 6)),
        updatedAt: dayOf(t).isAfter(monthOf(t))
            ? monthOf(t).add(const Duration(hours: 9))
            : t,
      ).toRow(),
    );
    await db.insert(
      Tbl.quotaOffers,
      QuotaOffer(
        id: newId(),
        cooperativeId: coop.id,
        ownerId: siti,
        kind: QuotaKind.share,
        kwh: 3,
        slotNote: '',
        note: 'Saya tidak produksi hari Minggu.',
        status: QuotaStatus.open,
        createdAt: t.subtract(const Duration(days: 1)),
        updatedAt: t.subtract(const Duration(days: 1)),
      ).toRow(),
    );

    // A member short on quota, so the share/need matching has something to show.
    await db.insert(
      Tbl.quotaOffers,
      QuotaOffer(
        id: newId(),
        cooperativeId: coop.id,
        ownerId: ids[3],
        kind: QuotaKind.need,
        kwh: 4,
        slotNote: '',
        note: 'Ada pesanan kue besar minggu ini.',
        status: QuotaStatus.open,
        createdAt: t.subtract(const Duration(days: 2)),
        updatedAt: t.subtract(const Duration(days: 2)),
      ).toRow(),
    );

    // Sent to Ibu Clara specifically, so the "Kuota untuk Anda" inbox has an
    // item to accept in the demo.
    await db.insert(
      Tbl.quotaOffers,
      QuotaOffer(
        id: newId(),
        cooperativeId: coop.id,
        ownerId: siti,
        kind: QuotaKind.share,
        kwh: 2,
        slotNote: '',
        note: 'Untuk kebutuhan katering minggu ini.',
        status: QuotaStatus.pending,
        counterpartyId: clara,
        createdAt: t.subtract(const Duration(hours: 5)),
        updatedAt: t.subtract(const Duration(hours: 5)),
      ).toRow(),
    );

    final groupThread =
        db.first(
              Tbl.messageThreads,
              (r) => r['kind'] == 'group' && r['ref_id'] == group.id,
            )!['id']
            as String;
    const chat = [
      (1, 'Selamat pagi ibu-ibu, iuran bulan ini sudah bisa disetor ya.'),
      (0, 'Siap Bu, saya sudah setor lewat aplikasi.'),
      (2, 'Minggu ini saya ada sisa kuota hub, siapa yang butuh?'),
    ];
    for (int i = 0; i < chat.length; i++) {
      await db.insert(
        Tbl.messages,
        Message(
          id: newId(),
          threadId: groupThread,
          senderId: ids[chat[i].$1],
          body: chat[i].$2,
          createdAt: t.subtract(Duration(hours: 20 - i * 3)),
        ).toRow(),
      );
    }

    // Past months' Skor Kredit Energi for Clara, so the score trend chart
    // has something to show on a fresh sample install — a real member only
    // gets one of these per month, on login (see actions._recordScoreSnapshot).
    // Trends up into the documented canonical 82 for the current month
    // (RuleBasedCreditScoringEngine's doc comment), which is computed live.
    const claraPastScores = [68, 72, 76, 79]; // oldest to newest, back=4..1
    for (int i = 0; i < claraPastScores.length; i++) {
      final month = monthsAgo(claraPastScores.length - i);
      await db.insert(
        Tbl.scoreSnapshots,
        ScoreSnapshot(
          id: newId(),
          userId: clara,
          month: month,
          score: claraPastScores[i],
          factorPoints: const {},
          createdAt: month.add(const Duration(days: 25)),
        ).toRow(),
      );
    }

    // One application in the admin's queue, submitted through the real rules.
    try {
      await LocalLoanRepository(db, now, engine).submit(
        me: Profile.fromRow(db.find(Tbl.profiles, siti)!),
        amountIdr: 1000000,
        purpose: LoanPurpose.equipment,
        tenorMonths: 6,
        note: 'Untuk mesin obras baru.',
      );
    } catch (_) {
      // Siti's sample history may fall short of the cooperative minimum; the
      // sample still works without a queued application.
    }

    await auth.logout();
  }
}
