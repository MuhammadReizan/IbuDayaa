import '../../../features/credit_score/domain/credit_scoring_engine.dart';
import '../../db/ids.dart';
import '../../db/local_database.dart';
import '../../db/row.dart';
import '../../db/tables.dart';
import '../../hub_qr.dart';
import '../../logic/hub_capacity.dart';
import '../../logic/loan_math.dart';
import '../../paths.dart';
import '../../models/models.dart';
import 'local_arisan_repository.dart';
import 'local_auth_repository.dart';
import 'local_loan_repository.dart';
import 'local_solar_repository.dart';

/// One sample member: who she is, what she owns, and how she uses the hub.
///
/// A session is one booking: a slot (index into the hub's ordered slots), the
/// appliances she runs in it and how many times a month she does. Its kWh is
/// the same estimate the app makes for a real booking — those appliances'
/// watts × the slot's hours — so a month adds up to what she really used and
/// stays within her [kMemberMonthlyKwh] quota.
class _SampleMember {
  const _SampleMember(
    this.phone,
    this.name,
    this.business,
    this.appliances,
    this.sessions, {
    this.joinedMonthsAgo,
  });

  final String phone;
  final String name;
  final String business;

  /// (name, kind, watts)
  final List<(String, String, double)> appliances;

  /// (slot index, appliance names running together, sessions per month)
  final List<(int, List<String>, int)> sessions;

  /// Joined at the start of that many calendar months ago; null = from the
  /// beginning. Recent joiners have too little history for a score yet.
  final int? joinedMonthsAgo;

  double wattsOf(List<String> use) => appliances
      .where((a) => use.contains(a.$1))
      .fold<double>(0, (s, a) => s + a.$3);
}

/// Five members, each there to be explored differently: Clara is the clean demo
/// account (full history, a score trend, free to apply for a loan), Siti has an
/// application waiting for review and an arisan payment waiting for the admin,
/// Lina is behind (no arisan payment, an overdue installment), Putri is near
/// her 35 kWh and is repaying a loan, Dewi is new (no score yet). Slots:
/// 0 = 08–10, 1 = 10–12, 2 = 12–15, 3 = 15–17. A month's kWh is in the comment.
const List<_SampleMember> _roster = [
  // ≈ 24.5 kWh
  _SampleMember(
    '081200000002',
    'Ibu Clara',
    'Katering Clara',
    [
      ('Oven', 'oven', 1500),
      ('Kulkas', 'refrigerator', 150),
      ('Blender', 'blender', 350),
      ('Rice Cooker Besar', 'other', 600),
    ],
    [
      (0, ['Oven'], 6),
      (3, ['Blender'], 5),
    ],
  ),
  // ≈ 13.9 kWh
  _SampleMember(
    '081200000003',
    'Siti Rahma',
    'Jahit Siti',
    [
      ('Mesin Jahit', 'sewingMachine', 100),
      ('Setrika Uap', 'other', 1000),
      ('Lampu & Kipas', 'other', 150),
    ],
    [
      (2, ['Setrika Uap', 'Mesin Jahit'], 3),
      (1, ['Mesin Jahit', 'Lampu & Kipas'], 8),
    ],
  ),
  // ≈ 19.2 kWh
  _SampleMember(
    '081200000004',
    'Ibu Lina',
    'Kue Basah Lina',
    [
      ('Mixer', 'other', 400),
      ('Oven', 'oven', 1000),
      ('Kukusan', 'other', 1200),
    ],
    [
      (0, ['Mixer', 'Oven'], 3),
      (2, ['Kukusan'], 3),
    ],
  ),
  // ≈ 32 kWh — close to her limit, so she asks for more
  _SampleMember(
    '081200000005',
    'Ibu Putri',
    'Warung Putri',
    [
      ('Kulkas', 'refrigerator', 120),
      ('Freezer Es', 'refrigerator', 250),
      ('Dispenser', 'other', 350),
      ('Timbangan Digital', 'other', 20),
      ('Oven Kecil', 'oven', 1200),
    ],
    [
      (3, ['Kulkas', 'Freezer Es', 'Timbangan Digital'], 18),
      (2, ['Oven Kecil'], 5),
    ],
  ),
  // ≈ 12 kWh — joined last month, so there is not enough history for a score
  // yet. She uses little and shares the rest; her light session is the one
  // that scans the hub QR in the sample.
  _SampleMember(
    '081200000006',
    'Ibu Dewi',
    'Songket Dewi',
    [
      ('Setrika Uap', 'other', 1000),
      ('Lampu Kerja', 'other', 200),
      ('Mesin Obras', 'sewingMachine', 250),
    ],
    [
      (3, ['Lampu Kerja', 'Mesin Obras'], 8),
      (1, ['Setrika Uap', 'Lampu Kerja'], 2),
    ],
    joinedMonthsAgo: 1,
  ),
];

/// A sample cooperative for trying the app or running the competition demo.
///
/// Local mode only, and only when the user taps "Coba dengan data contoh" on
/// the welcome screen — a fresh install never shows invented numbers. Every
/// account it creates is listed on that screen so nobody mistakes it for real.
///
/// The numbers follow the hub's sizing: each of the 15 members is promised
/// [kMemberMonthlyKwh] a month (35 kWh), so the hub gives
/// 15 × 35 ÷ 30 = 17.5 kWh a day (about a 5.5 kWp array). Every booked session
/// is appliance watts × slot hours and is placed only where the slot's
/// energy, the inverter and the member's own month still have room, so nothing
/// in the sample exceeds what the hub or her quota allows (checked in
/// `test/unit/repositories/workflow_test.dart`).
class SampleSeeder {
  SampleSeeder(this.db, this.now, this.engine);

  final LocalDatabase db;
  final DateTime Function() now;
  final CreditScoringEngine engine;

  static const String pin = '147258';
  static const String adminPhone = '081200000001';
  static const String memberPhone = '081200000002';

  static final List<({String phone, String name, String business})> members = [
    for (final m in _roster)
      (phone: m.phone, name: m.name, business: m.business),
  ];

  /// Matches the tariff the sample records were priced at.
  static const double _tariffIdrPerKwh = 1444.70;

  bool get isSeeded =>
      db.first(Tbl.profiles, (r) => r['phone'] == '+6281200000001') != null;

  Future<void> seed() async {
    if (isSeeded) return;
    final t = now();
    final today = dayOf(t);
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

    // Registered in roster order; that order is also the arisan turn order.
    final ids = <String>[];
    final joined = <String, DateTime>{};
    for (final m in _roster) {
      final p = await auth.registerMember(
        phone: m.phone,
        pin: pin,
        fullName: m.name,
        businessName: m.business,
        city: 'Palembang',
        inviteCode: coop.inviteCode,
      );
      ids.add(p.id);
      final ago = m.joinedMonthsAgo;
      joined[p.id] = ago == null ? start : monthsAgo(ago);
      if (ago != null) {
        await db.update(Tbl.profiles, p.id, {'created_at': ts(joined[p.id]!)});
      }
    }
    final clara = ids[0];
    final siti = ids[1];
    final lina = ids[2];
    final putri = ids[3];
    final dewi = ids[4];

    // Hub rating the admin would enter from the installation.
    final hub = SolarHub.fromRow(
      db.first(Tbl.solarHubs, (r) => r['cooperative_id'] == coop.id)!,
    );
    // The hub is built for a full cooperative of 15 members, of whom five have
    // joined so far: 15 × 35 kWh ÷ 30 days = 17.5 kWh a day, about a 5.5 kWp
    // array at ~4 peak-sun hours × 0.8. The inverter is sized with the panels,
    // 5 kW; it limits appliances running at the same time, not the sum of
    // everyone's ratings.
    final dailyKwh = dailyCapacityForQuota(
      members: 15,
      monthlyQuotaKwh: kMemberMonthlyKwh,
    );
    const maxLoadKw = 5.0;
    await db.update(Tbl.solarHubs, hub.id, {
      'name': 'Solar Hub Balai Melati',
      'location': 'Balai Warga RT 03, Palembang',
      'daily_capacity_kwh': dailyKwh,
      'max_load_kw': maxLoadKw,
      'max_members_per_slot': kDefaultMembersPerSlot,
    });
    final slots =
        db
            .select(Tbl.hubSlots, (r) => r['hub_id'] == hub.id)
            .map(HubSlot.fromRow)
            .toList()
          ..sort((a, b) => a.sort.compareTo(b.sort));

    for (int k = 0; k < _roster.length; k++) {
      final m = _roster[k];
      for (final (name, kind, watts) in m.appliances) {
        // Hours and days come from how often and how long she books it.
        final uses = m.sessions.where((s) => s.$2.contains(name)).toList();
        final times = uses.fold<int>(0, (s, x) => s + x.$3);
        final hoursTotal = uses.fold<int>(
          0,
          (s, x) => s + slots[x.$1].hours * x.$3,
        );
        await db.insert(
          Tbl.appliances,
          Appliance(
            id: newId(),
            userId: ids[k],
            name: name,
            kind: kind,
            watts: watts,
            hoursPerDay: times == 0 ? 2 : hoursTotal / times,
            daysPerWeek: times == 0 ? 1 : (times / 4.3).ceil().clamp(1, 7),
            createdAt: joined[ids[k]]!,
          ).toRow(),
        );
      }
    }

    // Sample usage is hub usage: each completed session is a booking plus
    // the record the hub creates automatically when the admin confirms it
    // (same as AppActions.setBookingStatus).
    // What is already placed on each day and in each slot, and in each member's
    // month, so a session only goes where a seat, the day's energy, the inverter
    // and her quota still have room.
    final dayKwh = <String, double>{};
    final slotSeats = <String, Set<int>>{};
    final slotKw = <String, double>{};
    final monthKwh = <String, double>{};
    final planned =
        <({int k, (int, List<String>, int) s, DateTime day, double kwh})>[];

    String slotKey(DateTime d, int slot) => '${dateOnly(d)}|$slot';
    String monthKey(int k, DateTime d) => '$k|${d.year}-${d.month}';

    bool place(int k, (int, List<String>, int) s, DateTime day) {
      final watts = _roster[k].wattsOf(s.$2);
      final kwh = watts / 1000 * slots[s.$1].hours;
      final sk = slotKey(day, s.$1);
      final dk = dateOnly(day);
      final seated = slotSeats[sk] ?? const <int>{};
      if (seated.contains(k)) return false; // one seat per member
      if (seated.length >= kDefaultMembersPerSlot) return false;
      if ((dayKwh[dk] ?? 0) + kwh > dailyKwh + 1e-9) return false;
      if ((slotKw[sk] ?? 0) + watts / 1000 > maxLoadKw + 1e-9) return false;
      if ((monthKwh[monthKey(k, day)] ?? 0) + kwh > kMemberMonthlyKwh + 1e-9) {
        return false;
      }
      dayKwh[dk] = (dayKwh[dk] ?? 0) + kwh;
      slotSeats[sk] = {...seated, k};
      slotKw[sk] = (slotKw[sk] ?? 0) + watts / 1000;
      monthKwh[monthKey(k, day)] = (monthKwh[monthKey(k, day)] ?? 0) + kwh;
      planned.add((k: k, s: s, day: day, kwh: kwh));
      return true;
    }

    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    // Today and tomorrow only for the members beyond the four demo logins, so
    // those four still go through book → scan themselves. Today, a slot that
    // has not ended yet only gets light sessions — a booked slot reads as
    // used, and the demo members should find room.
    bool allowed(int k, DateTime day, int slot, double kwh) {
      if (day.isBefore(today)) return true;
      if (k < 4 || day.isAfter(tomorrow)) return false;
      if (day.isAtSameMomentAs(tomorrow)) return true;
      return t.hour >= slots[slot].endHour || kwh <= 1.0;
    }

    final months = {
      for (int back = 4; back >= 0; back--) monthsAgo(back),
      DateTime(tomorrow.year, tomorrow.month),
    }.toList()..sort();
    for (final mo in months) {
      final len = DateTime(mo.year, mo.month + 1, 0).day;
      // A busy month is never exactly like the last: a session more or fewer, the
      // same every run. Her quota still caps what is placed.
      int sessionsIn(int k, int ti, DateTime month) {
        final base = _roster[k].sessions[ti].$3;
        if (base < 4) return base; // a handful of sessions stays a handful
        final delta = (k * 5 + ti * 3 + month.month * 7 + month.year) % 3 - 1;
        return base + delta;
      }

      // Each session type is spread evenly over the month, offset per member
      // so people do not all come on the same days; the same days every run.
      final wanted =
          <({int k, (int, List<String>, int) s, int ti, DateTime day})>[
            for (int k = 0; k < _roster.length; k++)
              for (int ti = 0; ti < _roster[k].sessions.length; ti++)
                for (int j = 0; j < sessionsIn(k, ti, mo); j++)
                  (
                    k: k,
                    s: _roster[k].sessions[ti],
                    ti: ti,
                    day: DateTime(
                      mo.year,
                      mo.month,
                      ((j + 0.5) * len / sessionsIn(k, ti, mo) + k * 3 + ti * 5)
                                  .floor() %
                              len +
                          1,
                    ),
                  ),
          ]..sort((a, b) {
            final byDay = a.day.compareTo(b.day);
            return byDay != 0 ? byDay : a.k.compareTo(b.k);
          });
      for (final w in wanted) {
        final from = joined[ids[w.k]]!.isAfter(monthsAgo(4))
            ? dayOf(joined[ids[w.k]]!)
            : monthsAgo(4);
        // A full slot pushes the session to the next days, within the month.
        for (int shift = 0; shift < 7; shift++) {
          final day = DateTime(w.day.year, w.day.month, w.day.day + shift);
          if (day.month != mo.month) break;
          if (day.isBefore(from)) continue;
          final kwh = _roster[w.k].wattsOf(w.s.$2) / 1000 * slots[w.s.$1].hours;
          if (!allowed(w.k, day, w.s.$1, kwh)) {
            // Nothing is planned for the demo members or beyond tomorrow; a
            // heavy session today moves to tomorrow instead.
            if (w.k < 4 || day.isAfter(tomorrow)) break;
            continue;
          }
          if (place(w.k, w.s, day)) break;
        }
      }
    }

    // Dewi is the one who arrives and scans the hub QR below, so she needs a
    // booking for today whose slot has not ended (her light afternoon session).
    final dewiToday = _roster[4].sessions.firstWhere((s) => s.$1 == 3);
    final dewiHasToday = planned.any(
      (p) => p.k == 4 && p.day.isAtSameMomentAs(today),
    );
    if (!dewiHasToday && t.hour < slots[dewiToday.$1].endHour) {
      place(4, dewiToday, today);
    }

    Future<void> insertSession(
      ({int k, (int, List<String>, int) s, DateTime day, double kwh}) p,
    ) async {
      final slot = slots[p.s.$1];
      final ended = p.day.isBefore(today) || t.hour >= slot.endHour;
      final status = p.day.isBefore(today) || p.day.isAtSameMomentAs(today)
          ? (ended ? BookingStatus.completed : BookingStatus.booked)
          : BookingStatus.booked;
      // A booked session whose slot has begun: the member has arrived. Dewi is
      // left un-arrived because she scans below.
      final arrived =
          status == BookingStatus.booked &&
          p.day.isAtSameMomentAs(today) &&
          t.hour >= slot.startHour &&
          p.k != 4;
      final bookingId = newId();
      await db.insert(
        Tbl.hubBookings,
        HubBooking(
          id: bookingId,
          hubId: hub.id,
          slotId: slot.id,
          userId: ids[p.k],
          applianceName: p.s.$2.join(', '),
          bookingDate: p.day,
          estKwh: p.kwh,
          status: status,
          createdAt: p.day.subtract(const Duration(hours: 10)),
          loadKw: _roster[p.k].wattsOf(p.s.$2) / 1000,
          requestedAt: arrived
              ? DateTime(p.day.year, p.day.month, p.day.day, slot.startHour, 5)
              : null,
        ).toRow(),
      );
      if (status != BookingStatus.completed) return;
      await db.insert(
        Tbl.energyRecords,
        EnergyRecord(
          id: newId(),
          userId: ids[p.k],
          kind: EnergyKind.token,
          periodMonth: monthOf(p.day),
          kwh: p.kwh,
          totalIdr: (p.kwh * _tariffIdrPerKwh).round(),
          source: RecordSource.hub,
          bookingId: bookingId,
          createdAt: p.day.add(Duration(hours: slot.endHour)),
        ).toRow(),
      );
    }

    await db.transaction(() async {
      for (final p in planned) {
        await insertSession(p);
      }
    });

    // Dewi arrives and scans the hub QR through the real flow: the request
    // (and the admin's notification) wait for the admin to approve.
    try {
      await LocalSolarRepository(db, now).requestConnection(
        me: Profile.fromRow(db.find(Tbl.profiles, dewi)!),
        scannedCode: kSolarHubQr,
        applianceName: 'Lampu Kerja, Mesin Obras',
        estKwh: 0,
      );
    } catch (_) {
      // After the last slot she has nothing booked to scan for.
    }

    // Dewi joined last month and is not in the arisan circle yet.
    final arisanIds = [
      for (int k = 0; k < _roster.length; k++)
        if (_roster[k].joinedMonthsAgo == null) ids[k],
    ];
    final arisan = LocalArisanRepository(db, () => monthsAgo(4));
    final group = await arisan.createGroup(
      admin: admin,
      name: 'Arisan Digital Melati',
      contributionIdr: 150000,
      startMonth: monthsAgo(4),
      memberIdsInTurnOrder: arisanIds,
    );

    for (int back = 4; back >= 0; back--) {
      final month = monthsAgo(back);
      for (final id in arisanIds) {
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
            userId: arisanIds[(4 - back) % arisanIds.length],
            type: PaymentType.payout,
            amountIdr: 150000 * arisanIds.length,
            periodMonth: month,
            status: PaymentStatus.confirmed,
            reviewedBy: admin.id,
            reviewedAt: month.add(const Duration(days: 20)),
            createdAt: month.add(const Duration(days: 20)),
          ).toRow(),
        );
      }
    }

    // Tukar Kuota, sized against a 35 kWh month: trades are a few kWh at a time
    // (the 1/2/3/5 kWh choices in the app).
    Future<void> offer({
      required String owner,
      required QuotaKind kind,
      required double kwh,
      required String note,
      required QuotaStatus status,
      required DateTime at,
      String? counterparty,
      DateTime? updatedAt,
    }) => db.insert(
      Tbl.quotaOffers,
      QuotaOffer(
        id: newId(),
        cooperativeId: coop.id,
        ownerId: owner,
        kind: kind,
        kwh: kwh,
        slotNote: '',
        note: note,
        status: status,
        counterpartyId: counterparty,
        createdAt: at,
        updatedAt: updatedAt ?? at,
      ).toRow(),
    );

    // Completed trades count in the month they were completed.
    final thisMonthStart = monthOf(t);
    await offer(
      owner: clara,
      kind: QuotaKind.share,
      kwh: 2,
      note: 'Sisa kuota minggu ini.',
      status: QuotaStatus.completed,
      counterparty: lina,
      at: t.subtract(const Duration(days: 6)),
      updatedAt: today.isAfter(thisMonthStart)
          ? thisMonthStart.add(const Duration(hours: 9))
          : t,
    );
    await offer(
      owner: dewi,
      kind: QuotaKind.share,
      kwh: 5,
      note: 'Pesanan songket sepi bulan ini.',
      status: QuotaStatus.completed,
      counterparty: lina,
      at: monthsAgo(1).add(const Duration(days: 8)),
      updatedAt: monthsAgo(1).add(const Duration(days: 9)),
    );
    await offer(
      owner: clara,
      kind: QuotaKind.share,
      kwh: 3,
      note: 'Untuk pesanan kue Lebaran.',
      status: QuotaStatus.completed,
      counterparty: putri,
      at: monthsAgo(2).add(const Duration(days: 4)),
      updatedAt: monthsAgo(2).add(const Duration(days: 5)),
    );
    await offer(
      owner: siti,
      kind: QuotaKind.share,
      kwh: 3,
      note: 'Saya tidak produksi hari Minggu.',
      status: QuotaStatus.open,
      at: t.subtract(const Duration(days: 1)),
    );
    await offer(
      owner: dewi,
      kind: QuotaKind.share,
      kwh: 6,
      note: 'Bulan ini produksi songket sedang sepi.',
      status: QuotaStatus.open,
      at: t.subtract(const Duration(hours: 30)),
    );
    // Members short on quota, so the share/need matching has something to show.
    await offer(
      owner: putri,
      kind: QuotaKind.need,
      kwh: 4,
      note: 'Ada pesanan kue besar minggu ini.',
      status: QuotaStatus.open,
      at: t.subtract(const Duration(days: 2)),
    );
    await offer(
      owner: lina,
      kind: QuotaKind.need,
      kwh: 3,
      note: 'Musim hajatan, pesanan kue meningkat.',
      status: QuotaStatus.open,
      at: t.subtract(const Duration(days: 3)),
    );
    // Sent to Ibu Clara specifically, so the "Kuota untuk Anda" inbox has an
    // item to accept in the demo.
    await offer(
      owner: siti,
      kind: QuotaKind.share,
      kwh: 2,
      note: 'Untuk kebutuhan katering minggu ini.',
      status: QuotaStatus.pending,
      counterparty: clara,
      at: t.subtract(const Duration(hours: 5)),
    );

    final groupThread =
        db.first(
              Tbl.messageThreads,
              (r) => r['kind'] == 'group' && r['ref_id'] == group.id,
            )!['id']
            as String;
    final chat = [
      (siti, 'Selamat pagi ibu-ibu, iuran bulan ini sudah bisa disetor ya.'),
      (clara, 'Siap Bu, saya sudah setor lewat aplikasi.'),
      (clara, 'Kuota saya masih banyak, kalau ada yang kurang bilang ya.'),
      (
        putri,
        'Saya butuh tambahan kuota untuk pesanan kue, Bu. Sudah saya '
            'posting di Tukar Kuota.',
      ),
      (
        siti,
        'Bu Lina, iuran bulan ini belum masuk ya. Ditunggu sampai akhir '
            'bulan.',
      ),
      (lina, 'Maaf Bu, minggu ini saya setor.'),
    ];
    for (int i = 0; i < chat.length; i++) {
      await db.insert(
        Tbl.messages,
        Message(
          id: newId(),
          threadId: groupThread,
          senderId: chat[i].$1,
          body: chat[i].$2,
          createdAt: t.subtract(Duration(hours: 24 - i * 3)),
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

    // Applications at different stages of the admin's queue, all submitted
    // through the real rules; one that the rules refuse is simply left out.
    final loans = LocalLoanRepository(db, now, engine);
    Profile profile(String id) => Profile.fromRow(db.find(Tbl.profiles, id)!);
    Future<void> apply(
      String id,
      int amountIdr,
      LoanPurpose purpose,
      int tenor,
      String note, {
      bool review = false,
      bool approve = false,
    }) async {
      try {
        final loan = await loans.submit(
          me: profile(id),
          amountIdr: amountIdr,
          purpose: purpose,
          tenorMonths: tenor,
          note: note,
        );
        if (review || approve) {
          await loans.startReview(admin: admin, loanId: loan.id);
        }
        if (approve) {
          await loans.approve(
            admin: admin,
            loanId: loan.id,
            note: 'Usaha stabil, setoran arisan lancar.',
          );
        }
      } catch (_) {
        // This member's sample history may fall short of the cooperative
        // minimum; the sample still works without her application.
      }
    }

    await apply(
      siti,
      1000000,
      LoanPurpose.equipment,
      6,
      'Untuk mesin obras baru.',
    );

    // Loans already being repaid, each walked through the real flow with the
    // clock set to when it happened, so the installment schedule shows every
    // state: confirmed, waiting for the admin, rejected and overdue, upcoming.
    LocalLoanRepository loansAt(DateTime when) =>
        LocalLoanRepository(db, () => when, engine);
    Future<void> repay(
      String id,
      int amountIdr,
      LoanPurpose purpose,
      int tenor,
      String note,
      DateTime disbursedAt, {
      Map<int, String> plan = const {},
    }) async {
      try {
        // Submitted through the real rules with today's data — judging her at
        // a past date would see only part of the history — then dated back to
        // when she would have applied.
        final submittedAt = disbursedAt.subtract(const Duration(days: 6));
        final loan = await loans.submit(
          me: profile(id),
          amountIdr: amountIdr,
          purpose: purpose,
          tenorMonths: tenor,
          note: note,
        );
        await db.update(Tbl.loanApplications, loan.id, {
          'created_at': ts(submittedAt),
        });
        for (final e in db.select(
          Tbl.loanEvents,
          (r) => r['loan_id'] == loan.id,
        )) {
          await db.update(Tbl.loanEvents, e['id'] as String, {
            'created_at': ts(submittedAt),
          });
        }
        for (final n in db.select(
          Tbl.notifications,
          (r) => r['route'] == Paths.adminLoan(loan.id),
        )) {
          await db.update(Tbl.notifications, n['id'] as String, {
            'created_at': ts(submittedAt),
          });
        }
        await loansAt(
          disbursedAt.subtract(const Duration(days: 4)),
        ).startReview(admin: admin, loanId: loan.id);
        await loansAt(disbursedAt.subtract(const Duration(days: 3))).approve(
          admin: admin,
          loanId: loan.id,
          note: 'Usaha stabil, setoran arisan lancar.',
        );
        await loansAt(disbursedAt).disburse(admin: admin, loanId: loan.id);
        final schedule =
            db
                .select(Tbl.loanInstallments, (r) => r['loan_id'] == loan.id)
                .map(LoanInstallment.fromRow)
                .toList()
              ..sort((a, b) => a.seq.compareTo(b.seq));
        for (final i in schedule) {
          DateTime around(int days, [int hour = 10]) => DateTime(
            i.dueDate.year,
            i.dueDate.month,
            i.dueDate.day + days,
            hour,
          );
          switch (plan[i.seq]) {
            case 'paid': // sent and confirmed before the due date
              await loansAt(
                around(-3),
              ).submitInstallmentPayment(me: profile(id), installmentId: i.id);
              await loansAt(
                around(-2),
              ).markInstallmentPaid(admin: admin, installmentId: i.id);
            case 'awaiting': // sent yesterday, still waiting for the admin
              await loansAt(
                t.subtract(const Duration(hours: 20)),
              ).submitInstallmentPayment(me: profile(id), installmentId: i.id);
            case 'rejected': // sent, but the amount did not match
              await loansAt(
                around(2),
              ).submitInstallmentPayment(me: profile(id), installmentId: i.id);
              await loansAt(around(3)).rejectInstallmentPayment(
                admin: admin,
                installmentId: i.id,
                reason:
                    'Nominal yang masuk kurang dari cicilan. Mohon kirim ulang.',
              );
          }
        }
      } catch (_) {
        // The member's sample history may fall short of the rules at that
        // date; the sample still works without her loan.
      }
    }

    DateTime monthsBack(int n, {int days = 0}) {
      final d = addMonthsClamped(today, -n).add(Duration(days: days));
      return DateTime(d.year, d.month, d.day, 10);
    }

    // Putri: disbursed two months ago. #1 was confirmed in time; #2 falls due
    // today and was sent yesterday, so it waits for the admin.
    await repay(
      putri,
      2000000,
      LoanPurpose.equipment,
      6,
      'Untuk freezer baru.',
      monthsBack(2),
      plan: {1: 'paid', 2: 'awaiting'},
    );
    // Lina: disbursed a month and 12 days ago. #1 is overdue after the admin
    // rejected the payment she sent, the same month she has not paid arisan.
    await repay(
      lina,
      1500000,
      LoanPurpose.rawMaterial,
      3,
      'Stok bahan kue untuk pesanan hajatan.',
      monthsBack(1, days: -12),
      plan: {1: 'rejected'},
    );

    // Welcome and status messages the app posted along the way are read; only
    // the arisan group's chat is left for people to open.
    final groupThreadIds = {
      for (final th in db.select(Tbl.messageThreads))
        if (th['kind'] == 'group') th['id'] as String,
    };
    for (final p in db.select(Tbl.threadParticipants)) {
      if (groupThreadIds.contains(p['thread_id'])) continue;
      await db.update(Tbl.threadParticipants, p['id'] as String, {
        'last_read_at': ts(t),
      });
    }

    // Notifications from a few days back are history, not news.
    final stale = t.subtract(const Duration(days: 2));
    for (final n in db.select(
      Tbl.notifications,
      (r) => r['read_at'] == null && rDate(r, 'created_at').isBefore(stale),
    )) {
      await db.update(Tbl.notifications, n['id'] as String, {'read_at': ts(t)});
    }

    await auth.logout();
  }
}
