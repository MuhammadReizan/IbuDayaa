import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/hub_qr.dart';
import 'package:ibudaya/core/logic/hub_capacity.dart';
import 'package:ibudaya/core/paths.dart';
import 'package:ibudaya/core/db/local_database.dart';
import 'package:ibudaya/core/db/row.dart';
import 'package:ibudaya/core/db/tables.dart';
import 'package:ibudaya/core/errors.dart';
import 'package:ibudaya/core/models/models.dart';
import 'package:ibudaya/core/repositories/local/local_arisan_repository.dart';
import 'package:ibudaya/core/repositories/local/local_auth_repository.dart';
import 'package:ibudaya/core/repositories/local/local_loan_repository.dart';
import 'package:ibudaya/core/repositories/local/local_snapshot_repository.dart';
import 'package:ibudaya/core/repositories/local/local_solar_repository.dart';
import 'package:ibudaya/core/repositories/local/sample_seeder.dart';
import 'package:ibudaya/core/state/selectors.dart';
import 'package:ibudaya/features/credit_score/data/rule_based_credit_scoring_engine.dart';

void main() {
  final now = DateTime(2026, 9, 11, 10);
  DateTime clock() => now;
  const engine = RuleBasedCreditScoringEngine();

  late LocalDatabase db;
  late LocalAuthRepository auth;
  late LocalSnapshotRepository snapshots;

  setUp(() async {
    db = await LocalDatabase.open(MemoryDbStorage());
    auth = LocalAuthRepository(db, clock);
    snapshots = LocalSnapshotRepository(db, clock);
    await SampleSeeder(db, clock, engine).seed();
  });

  Future<Profile> login(String phone) =>
      auth.login(phone: phone, pin: SampleSeeder.pin);

  /// The slot running at [at], booked for that day — a QR scan needs one.
  Future<HubBooking> bookRunningSlot(
    LocalSolarRepository solar,
    Profile member,
    DateTime at, {
    double estKwh = 3,
    double loadKw = 2,
  }) async {
    final slot = (await snapshots.load(member)).orderedSlots.firstWhere(
      (x) => x.startHour <= at.hour && at.hour < x.endHour,
    );
    return solar.book(
      me: member,
      slotId: slot.id,
      date: dayOf(at),
      applianceName: 'Oven',
      estKwh: estKwh,
      loadKw: loadKw,
    );
  }

  test('sample cooperative seeds once and nobody stays signed in', () async {
    expect(await auth.restoreSession(), isNull);
    await SampleSeeder(db, clock, engine).seed();
    final admin = await login(SampleSeeder.adminPhone);
    final data = await snapshots.load(admin);
    expect(data.memberProfiles, hasLength(SampleSeeder.members.length));
    expect(data.hub!.isConfigured, isTrue);
  });

  test('a member sees only her own records; the admin sees everyone', () async {
    final clara = await login(SampleSeeder.memberPhone);
    final mine = await snapshots.load(clara);
    expect(mine.energyRecords, isNotEmpty);
    expect(mine.energyRecords.every((r) => r.userId == clara.id), isTrue);
    expect(mine.loans.every((l) => l.userId == clara.id), isTrue);

    final admin = await login(SampleSeeder.adminPhone);
    final all = await snapshots.load(admin);
    expect(
      all.energyRecords.map((r) => r.userId).toSet().length,
      greaterThan(1),
    );
    expect(all.loansAwaitingAdmin, isNotEmpty);
  });

  test('loan: submit → review → approve → disburse → repaid', () async {
    final loans = LocalLoanRepository(db, clock, engine);
    final clara = await login(SampleSeeder.memberPhone);
    final before = await snapshots.load(clara);
    final score = before.scoreOf(clara.id, now, engine);
    expect(score, isNotNull);

    final app = await loans.submit(
      me: clara,
      amountIdr: 2000000,
      purpose: LoanPurpose.equipment,
      tenorMonths: 6,
    );
    expect(app.status, LoanStatus.submitted);
    expect(app.scoreSnapshot, score!.score);

    await expectLater(
      loans.submit(
        me: clara,
        amountIdr: 1000000,
        purpose: LoanPurpose.other,
        tenorMonths: 3,
      ),
      throwsA(isA<AppException>()),
      reason: 'one active application at a time',
    );
    await expectLater(
      loans.approve(admin: clara, loanId: app.id),
      throwsA(isA<AppException>()),
      reason: 'members cannot decide loans',
    );

    final admin = await login(SampleSeeder.adminPhone);
    await loans.startReview(admin: admin, loanId: app.id);
    await loans.approve(admin: admin, loanId: app.id, note: 'Lengkap.');
    await loans.disburse(admin: admin, loanId: app.id);

    var data = await snapshots.load(admin);
    final schedule = data.installmentsOf(app.id);
    expect(schedule, hasLength(6));
    expect(
      schedule.fold<int>(0, (s, i) => s + i.amountIdr),
      app.totalRepaymentIdr,
    );

    for (final i in schedule) {
      await loans.markInstallmentPaid(admin: admin, installmentId: i.id);
    }
    data = await snapshots.load(admin);
    expect(data.loan(app.id)!.status, LoanStatus.repaid);
    expect(data.eventsOf(app.id).length, greaterThanOrEqualTo(5));

    final claraView = await snapshots.load(clara);
    expect(claraView.notificationsOf(clara.id), isNotEmpty);
  });

  test('booking respects hub capacity and the member quota', () async {
    final solar = LocalSolarRepository(db, clock);
    final clara = await login(SampleSeeder.memberPhone);
    final data = await snapshots.load(clara);
    // A day the sample members have not booked (they book today and tomorrow).
    final tomorrow = DateTime(2026, 9, 14);
    final slot = data.orderedSlots[1];

    final booking = await solar.book(
      me: clara,
      slotId: slot.id,
      date: tomorrow,
      applianceName: 'Oven',
      estKwh: 3,
    );
    expect(booking.status, BookingStatus.booked);

    await expectLater(
      solar.book(
        me: clara,
        slotId: data.orderedSlots[2].id,
        date: tomorrow,
        applianceName: 'Oven',
        estKwh: 500,
      ),
      throwsA(isA<AppException>()),
      reason: 'more than the hub has for that day',
    );

    await expectLater(
      solar.setBookingStatus(clara, booking.id, BookingStatus.completed),
      throwsA(isA<AppException>()),
      reason: 'a session cannot be marked used before its date',
    );
  });

  test(
    'a pendingVerification request reserves capacity like a real booking',
    () async {
      final solar = LocalSolarRepository(db, clock);
      final clara = await login(SampleSeeder.memberPhone);
      await bookRunningSlot(solar, clara, now);

      final request = await solar.requestConnection(
        me: clara,
        scannedCode: kSolarHubQr,
        applianceName: 'Oven',
        estKwh: 3,
      );
      expect(request.status, BookingStatus.pendingVerification);

      final data = await snapshots.load(clara);
      final availability = data
          .availabilityOn(request.bookingDate)
          .firstWhere((a) => a.slot.id == request.slotId);
      expect(availability.bookedKwh, greaterThanOrEqualTo(3));

      await expectLater(
        solar.book(
          me: clara,
          slotId: request.slotId,
          date: request.bookingDate,
          applianceName: 'Setrika',
          estKwh: availability.dayRemainingKwh + 10,
        ),
        throwsA(isA<AppException>()),
        reason: 'the pending request already reserved part of this slot',
      );
    },
  );

  test('a scan without a booking for today asks her to book first', () async {
    final solar = LocalSolarRepository(db, clock);
    final clara = await login(SampleSeeder.memberPhone);
    await expectLater(
      solar.requestConnection(
        me: clara,
        scannedCode: kSolarHubQr,
        applianceName: 'Oven',
        estKwh: 3,
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('Booking slot dulu'),
        ),
      ),
    );
    expect(
      (await snapshots.load(clara)).latestHubRequestOf(clara.id, now),
      isNull,
      reason: 'a refused scan leaves no request behind',
    );
  });

  test("requestConnection rejects a QR that is not the hub's", () async {
    final solar = LocalSolarRepository(db, clock);
    final clara = await login(SampleSeeder.memberPhone);

    await expectLater(
      solar.requestConnection(
        me: clara,
        scannedCode: 'NOT-THE-HUB-QR',
        applianceName: 'Oven',
        estKwh: 3,
      ),
      throwsA(isA<AppException>()),
    );
  });

  test(
    'requestConnection succeeds during the 12.00-13.00 slot '
    '(regression: default slots used to skip straight from 12 to 13)',
    () async {
      final solar = LocalSolarRepository(
        db,
        () => DateTime(2026, 9, 11, 12, 30),
      );
      final clara = await login(SampleSeeder.memberPhone);
      await bookRunningSlot(
        solar,
        clara,
        DateTime(2026, 9, 11, 12, 30),
        estKwh: 1,
      );

      final request = await solar.requestConnection(
        me: clara,
        scannedCode: kSolarHubQr,
        applianceName: 'Oven',
        estKwh: 1,
      );
      expect(request.status, BookingStatus.pendingVerification);

      final data = await snapshots.load(clara);
      final slot = data
          .availabilityOn(request.bookingDate)
          .firstWhere((a) => a.slot.id == request.slotId)
          .slot;
      expect(slot.startHour, lessThanOrEqualTo(12));
      expect(slot.endHour, greaterThan(12));
    },
  );

  test('addSlot rejects hours outside the sun-weighted 06.00-18.00 window '
      '(regression: solarWeight gives 0 capacity outside it, making such a '
      'slot unbookable forever even though it used to be allowed)', () async {
    final solar = LocalSolarRepository(db, clock);
    final admin = await login(SampleSeeder.adminPhone);
    final data = await snapshots.load(admin);
    final hubId = data.hub!.id;

    await expectLater(
      solar.addSlot(admin, hubId, 5, 6),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      solar.addSlot(admin, hubId, 18, 19),
      throwsA(isA<AppException>()),
    );
  });

  test(
    "a member's own hub allocation overrides the cooperative default",
    () async {
      final solar = LocalSolarRepository(db, clock);
      final admin = await login(SampleSeeder.adminPhone);
      var clara = await login(SampleSeeder.memberPhone);
      // Everything already drawn from her month, including quota she gave.
      final used = (await snapshots.load(clara)).quotaOf(clara.id, now);
      final existingBooked = used.bookedKwh + used.givenKwh - used.receivedKwh;
      final tomorrow = DateTime(2026, 9, 14);
      final data = await snapshots.load(clara);
      final slot = data.orderedSlots[1];

      clara = await solar.setMemberHubAllocation(
        admin: admin,
        memberId: clara.id,
        allocationKwh: existingBooked + 1,
      );
      await expectLater(
        solar.book(
          me: clara,
          slotId: slot.id,
          date: tomorrow,
          applianceName: 'Oven',
          estKwh: 3,
        ),
        throwsA(isA<AppException>()),
        reason: 'her own low allocation overrides the higher coop default',
      );

      clara = await solar.setMemberHubAllocation(
        admin: admin,
        memberId: clara.id,
        allocationKwh: existingBooked + 10,
      );
      final booking = await solar.book(
        me: clara,
        slotId: slot.id,
        date: tomorrow,
        applianceName: 'Oven',
        estKwh: 3,
      );
      expect(booking.status, BookingStatus.booked);
    },
  );

  test('each member gets 35 kWh a month, the hub is built for 15 and every '
      'sample member has an appliance to scan with', () async {
    final admin = await login(SampleSeeder.adminPhone);
    final data = await snapshots.load(admin);
    expect(kMemberMonthlyKwh, 35);
    expect(data.cooperative!.memberMonthlyQuotaKwh, 35);
    expect(SampleSeeder.members, hasLength(5));
    // Built for a full cooperative of 15 (15 × 35 ÷ 30 days), five joined so far.
    expect(data.hub!.dailyCapacityKwh, closeTo(17.5, 1e-9));
    expect(
      data.hub!.dailyCapacityKwh,
      dailyCapacityForQuota(members: 15, monthlyQuotaKwh: kMemberMonthlyKwh),
    );
    for (final m in SampleSeeder.members) {
      final p = await login(m.phone);
      expect(
        (await snapshots.load(p)).appliancesOf(p.id),
        isNotEmpty,
        reason: '${m.name} could not scan the hub QR without an appliance',
      );
    }
  });

  test('sample usage fits the hub: a member\'s day, a slot and a month stay '
      'within her 35 kWh, slot capacity and the inverter', () async {
    final admin = await login(SampleSeeder.adminPhone);
    final data = await snapshots.load(admin);
    final hub = data.hub!;
    final counted = data.bookings.where((b) => b.countsAgainstCapacity);

    final perMemberMonth = <String, double>{};
    for (final b in counted) {
      final month = '${b.userId}|${monthOf(b.bookingDate)}';
      perMemberMonth[month] = (perMemberMonth[month] ?? 0) + b.estKwh;
    }
    expect(perMemberMonth.values, isNotEmpty);
    // Heavy users run close to the limit; light ones leave room to share.
    expect(
      perMemberMonth.values.reduce((a, b) => a > b ? a : b),
      greaterThan(30),
    );
    expect(perMemberMonth.values.reduce((a, b) => a < b ? a : b), lessThan(20));
    for (final e in perMemberMonth.entries) {
      expect(
        e.value,
        lessThanOrEqualTo(data.cooperative!.memberMonthlyQuotaKwh),
        reason: e.key,
      );
    }

    final days = counted.map((b) => dayOf(b.bookingDate)).toSet();
    for (final d in days) {
      for (final a in data.availabilityOn(d)) {
        expect(a.bookedMembers, lessThanOrEqualTo(a.seatLimit), reason: '$d');
        expect(
          a.dayBookedKwh,
          lessThanOrEqualTo(a.dayCapacityKwh),
          reason: '$d',
        );
        expect(a.loadKw, lessThanOrEqualTo(hub.maxLoadKw), reason: '$d');
      }
    }
  });

  test('sample cooperative has demo material for every admin queue and '
      'one new member still without enough history for a score', () async {
    final admin = await login(SampleSeeder.adminPhone);
    final data = await snapshots.load(admin);
    expect(data.loans.map((l) => l.status), contains(LoanStatus.submitted));
    expect(data.offers.where((o) => o.status == QuotaStatus.open), isNotEmpty);
    expect(
      data.payments.where((p) => p.status == PaymentStatus.pending),
      isNotEmpty,
    );
    final withheld = [
      for (final p in data.memberProfiles)
        if (data.scoreOf(p.id, now, engine) == null) p.fullName,
    ];
    expect(withheld, unorderedEquals(['Ibu Dewi']));
  });

  test('a QR scan is never refused for energy, quota, load '
      'and closed slots (demo switch kQrIgnoresHubLimits)', () async {
    final solar = LocalSolarRepository(db, clock);
    final admin = await login(SampleSeeder.adminPhone);
    final clara = await login(SampleSeeder.memberPhone);
    final hubId = (await snapshots.load(admin)).hub!.id;
    await bookRunningSlot(solar, clara, now);

    // Exhaust everything: no quota, no slot energy, no inverter headroom.
    await solar.setMemberHubAllocation(
      admin: admin,
      memberId: clara.id,
      allocationKwh: 0,
    );
    final tiny = (await snapshots.load(
      admin,
    )).hub!.copyWith(dailyCapacityKwh: 0.1, maxLoadKw: 0.1);
    await db.update(Tbl.solarHubs, hubId, {
      'daily_capacity_kwh': tiny.dailyCapacityKwh,
      'max_load_kw': tiny.maxLoadKw,
    });
    final member = Profile.fromRow(db.find(Tbl.profiles, clara.id)!);
    for (final slot in (await snapshots.load(admin)).orderedSlots) {
      await solar.setSlotOpen(admin, slot.id, false);
    }

    for (int i = 0; i < 3; i++) {
      final request = await solar.requestConnection(
        me: member,
        scannedCode: kSolarHubQr,
        applianceName: 'Oven, Kulkas, Blender',
        estKwh: 8,
        loadKw: 2,
      );
      expect(request.status, BookingStatus.pendingVerification);
      await solar.respondToConnectionRequest(
        admin: admin,
        bookingId: request.id,
        approve: true,
      );
    }
  });

  test('arisan dues wait for the admin to confirm', () async {
    final arisan = LocalArisanRepository(db, clock);
    final lina = await login('081200000004');
    final group = (await snapshots.load(lina)).groupsOf(lina.id).single;
    final payment = await arisan.submitContribution(
      me: lina,
      groupId: group.id,
      periodMonth: now,
    );
    expect(payment.status, PaymentStatus.pending);

    final admin = await login(SampleSeeder.adminPhone);
    await arisan.reviewPayment(
      admin: admin,
      paymentId: payment.id,
      approve: true,
    );
    final data = await snapshots.load(lina);
    expect(
      data.contributionFor(group.id, lina.id, now)!.status,
      PaymentStatus.confirmed,
    );
  });

  test('joining needs a valid invite code; PIN locks after 5 misses', () async {
    await expectLater(
      auth.registerMember(
        phone: '081299999999',
        pin: '482915',
        fullName: 'Ibu Baru',
        businessName: 'Warung',
        city: 'Palembang',
        inviteCode: 'ZZZZZZ',
      ),
      throwsA(isA<AppException>()),
    );

    for (int i = 0; i < LocalAuthRepository.maxAttempts; i++) {
      await expectLater(
        auth.login(phone: SampleSeeder.memberPhone, pin: '000000'),
        throwsA(isA<AppException>()),
      );
    }
    await expectLater(
      login(SampleSeeder.memberPhone),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('Coba lagi'),
        ),
      ),
    );
  });

  test('answering a quota post completes the trade at once', () async {
    final arisan = LocalArisanRepository(db, clock);
    final clara = await login(SampleSeeder.memberPhone);
    final data = await snapshots.load(clara);
    final open = data.offers.firstWhere(
      (o) =>
          o.kind == QuotaKind.share &&
          o.status == QuotaStatus.open &&
          o.ownerId != clara.id,
    );
    final before = data.quotaOf(clara.id, now);

    await arisan.respondToQuota(me: clara, offerId: open.id);

    final after = await snapshots.load(clara);
    final done = after.offers.firstWhere((o) => o.id == open.id);
    expect(done.status, QuotaStatus.completed);
    expect(done.counterpartyId, clara.id);
    expect(
      after.quotaOf(clara.id, now).receivedKwh,
      closeTo(before.receivedKwh + open.kwh, 1e-9),
    );

    await expectLater(
      arisan.respondToQuota(me: clara, offerId: open.id),
      throwsA(isA<AppException>()),
      reason: 'a post can only be answered once',
    );
  });

  test('a need is answered only by a member who can afford to give', () async {
    final arisan = LocalArisanRepository(db, clock);
    final clara = await login(SampleSeeder.memberPhone);
    final need = (await snapshots.load(clara)).offers.firstWhere(
      (o) => o.kind == QuotaKind.need && o.status == QuotaStatus.open,
    );
    final before = (await snapshots.load(clara)).quotaOf(clara.id, now);

    await arisan.respondToQuota(me: clara, offerId: need.id);

    final after = (await snapshots.load(clara)).quotaOf(clara.id, now);
    expect(after.givenKwh, closeTo(before.givenKwh + need.kwh, 1e-9));
  });

  group('sending quota to a specific member', () {
    test('waits for her, then moves quota when she accepts', () async {
      final arisan = LocalArisanRepository(db, clock);
      final siti = await login('081200000003');
      final clara = await login(SampleSeeder.memberPhone);
      final beforeSiti = (await snapshots.load(siti)).quotaOf(siti.id, now);
      final beforeClara = (await snapshots.load(clara)).quotaOf(clara.id, now);

      final gift = await arisan.postQuota(
        me: siti,
        kind: QuotaKind.share,
        kwh: 4,
        toMemberId: clara.id,
      );
      expect(gift.status, QuotaStatus.pending);
      expect(gift.counterpartyId, clara.id);

      // Nothing has moved yet.
      expect(
        (await snapshots.load(siti)).quotaOf(siti.id, now).givenKwh,
        beforeSiti.givenKwh,
      );

      await expectLater(
        arisan.answerQuotaGift(me: siti, offerId: gift.id, accept: true),
        throwsA(isA<AppException>()),
        reason: 'only the receiver can answer',
      );

      await arisan.answerQuotaGift(me: clara, offerId: gift.id, accept: true);
      expect(
        (await snapshots.load(siti)).quotaOf(siti.id, now).givenKwh,
        closeTo(beforeSiti.givenKwh + 4, 1e-9),
      );
      expect(
        (await snapshots.load(clara)).quotaOf(clara.id, now).receivedKwh,
        closeTo(beforeClara.receivedKwh + 4, 1e-9),
      );
    });

    test('a declined gift moves nothing', () async {
      final arisan = LocalArisanRepository(db, clock);
      final siti = await login('081200000003');
      final clara = await login(SampleSeeder.memberPhone);
      final before = (await snapshots.load(clara)).quotaOf(clara.id, now);
      final gift = await arisan.postQuota(
        me: siti,
        kind: QuotaKind.share,
        kwh: 1,
        toMemberId: clara.id,
      );

      await arisan.answerQuotaGift(me: clara, offerId: gift.id, accept: false);

      final after = await snapshots.load(clara);
      expect(
        after.offers.firstWhere((o) => o.id == gift.id).status,
        QuotaStatus.cancelled,
      );
      expect(after.quotaOf(clara.id, now).receivedKwh, before.receivedKwh);
    });

    test('only a share can be sent, and only to another member', () async {
      final arisan = LocalArisanRepository(db, clock);
      final siti = await login('081200000003');
      final admin = await login(SampleSeeder.adminPhone);
      final clara = await login(SampleSeeder.memberPhone);

      await expectLater(
        arisan.postQuota(
          me: siti,
          kind: QuotaKind.need,
          kwh: 1,
          toMemberId: clara.id,
        ),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        arisan.postQuota(
          me: siti,
          kind: QuotaKind.share,
          kwh: 1,
          toMemberId: siti.id,
        ),
        throwsA(isA<AppException>()),
        reason: 'not to herself',
      );
      await expectLater(
        arisan.postQuota(
          me: siti,
          kind: QuotaKind.share,
          kwh: 1,
          toMemberId: admin.id,
        ),
        throwsA(isA<AppException>()),
        reason: 'not to the admin',
      );
    });
  });

  group('cooperative KPIs and the credit report', () {
    test('KPIs count what the sample cooperative actually did', () async {
      final admin = await login(SampleSeeder.adminPhone);
      final data = await snapshots.load(admin);
      final kpis = data.coopKpisOf(now, engine);

      expect(kpis.members, SampleSeeder.members.length);
      expect(kpis.activeMembers, greaterThan(0));
      expect(kpis.activeMembers, lessThanOrEqualTo(kpis.members));
      expect(kpis.loanReady, lessThanOrEqualTo(kpis.members));
      expect(kpis.installmentsOnTime, lessThanOrEqualTo(kpis.installmentsDue));
      // Three installments have fallen due in the sample: one confirmed in
      // time, one sent but still waiting for an admin (not counted as paid),
      // one overdue after its payment was rejected.
      expect(kpis.installmentsDue, 3);
      expect(kpis.installmentsOnTime, 1);
      expect(kpis.onTimePct, isNotNull);
    });

    test('a member with a score gets a report that matches it', () async {
      final clara = await login(SampleSeeder.memberPhone);
      final data = await snapshots.load(clara);
      final score = data.scoreOf(clara.id, now, engine)!;
      final report = data.creditReportOf(clara.id, now, engine)!;

      expect(report.score.score, score.score);
      expect(report.loanReady, data.loanReadyOf(clara.id, now, engine));
      final text = report.toPlainText();
      expect(text, contains('Skor: ${score.score}/100'));
      expect(text, contains('bukan model AI'));
      expect(text, contains('bukan keputusan pinjaman'));
      for (final f in score.factors) {
        expect(text, contains(f.label));
      }
    });

    test('no report without a score', () async {
      final admin = await login(SampleSeeder.adminPhone);
      final data = await snapshots.load(admin);
      expect(data.creditReportOf(admin.id, now, engine), isNull);
    });
  });

  group('installment payments', () {
    late LocalLoanRepository loans;
    late Profile admin;
    late Profile nur;
    late List<LoanInstallment> schedule;

    setUp(() async {
      loans = LocalLoanRepository(db, clock, engine);
      admin = await login(SampleSeeder.adminPhone);
      nur = await login('081200000005');
      final data = await snapshots.load(admin);
      final loan = data.loansOf(nur.id).single;
      schedule = data.installmentsOf(loan.id);
    });

    test('the sample has one payment waiting for an admin', () async {
      final data = await snapshots.load(admin);
      final waiting = data.installmentsAwaiting.single;
      expect(waiting.seq, 2);
      expect(waiting.isPaid, isFalse);
      expect(waiting.isAwaitingConfirmation, isTrue);
    });

    test('a member sends a payment, the admin confirms it, and it counts as '
        'paid on the day she sent it', () async {
      final next = schedule.firstWhere(
        (i) => !i.isPaid && !i.isAwaitingConfirmation,
      );
      await loans.submitInstallmentPayment(
        me: nur,
        installmentId: next.id,
        note: 'Transfer BCA',
      );
      var data = await snapshots.load(admin);
      expect(data.installmentsAwaiting.map((i) => i.id), contains(next.id));
      expect(
        data
            .notificationsOf(admin.id)
            .any((n) => n.route == Paths.adminInstallments && !n.isRead),
        isTrue,
        reason: 'the admin is told a payment is waiting',
      );

      await loans.markInstallmentPaid(admin: admin, installmentId: next.id);
      data = await snapshots.load(admin);
      final done = data.installments.firstWhere((i) => i.id == next.id);
      expect(done.isPaid, isTrue);
      expect(done.isAwaitingConfirmation, isFalse);
      expect(done.paidOnTime, isTrue);
      expect(done.submitNote, 'Transfer BCA');
    });

    test('a rejection needs a reason, is shown to the member, and the '
        'payment can be sent again', () async {
      final waiting = schedule.firstWhere((i) => i.isAwaitingConfirmation);
      await expectLater(
        loans.rejectInstallmentPayment(
          admin: admin,
          installmentId: waiting.id,
          reason: '  ',
        ),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        loans.rejectInstallmentPayment(
          admin: nur,
          installmentId: waiting.id,
          reason: 'Tidak boleh',
        ),
        throwsA(isA<AppException>()),
        reason: 'a member cannot review payments',
      );

      await loans.rejectInstallmentPayment(
        admin: admin,
        installmentId: waiting.id,
        reason: 'Nominal kurang',
      );
      var data = await snapshots.load(nur);
      final rejected = data.installments.firstWhere((i) => i.id == waiting.id);
      expect(rejected.wasRejected, isTrue);
      expect(rejected.reviewNote, 'Nominal kurang');
      expect(data.installmentsAwaiting, isEmpty);

      await loans.submitInstallmentPayment(me: nur, installmentId: waiting.id);
      data = await snapshots.load(nur);
      final again = data.installments.firstWhere((i) => i.id == waiting.id);
      expect(again.isAwaitingConfirmation, isTrue);
      expect(again.reviewNote, isNull);
    });

    test('installments are paid in order, only once, and only by the '
        'borrower', () async {
      final waiting = schedule.firstWhere((i) => i.isAwaitingConfirmation);
      final later = schedule.firstWhere((i) => i.seq == waiting.seq + 2);
      await expectLater(
        loans.submitInstallmentPayment(me: nur, installmentId: later.id),
        throwsA(isA<AppException>()),
        reason: 'the one before it is neither paid nor sent',
      );
      await expectLater(
        loans.submitInstallmentPayment(me: nur, installmentId: waiting.id),
        throwsA(isA<AppException>()),
        reason: 'already sent',
      );
      await expectLater(
        loans.submitInstallmentPayment(
          me: nur,
          installmentId: schedule.first.id,
        ),
        throwsA(isA<AppException>()),
        reason: 'already paid',
      );
      final clara = await login(SampleSeeder.memberPhone);
      await expectLater(
        loans.submitInstallmentPayment(me: clara, installmentId: later.id),
        throwsA(isA<AppException>()),
        reason: "someone else's loan",
      );
    });

    test('a slow confirmation does not make a payment late', () async {
      final waiting = schedule.firstWhere((i) => i.isAwaitingConfirmation);
      final late = LoanInstallment(
        id: 'x',
        loanId: waiting.loanId,
        seq: 1,
        dueDate: DateTime(2026, 9, 1),
        amountIdr: 1,
        submittedAt: DateTime(2026, 8, 31, 9),
        paidAt: DateTime(2026, 9, 4, 9),
      );
      expect(late.paidOnTime, isTrue);
      expect(
        LoanInstallment(
          id: 'y',
          loanId: waiting.loanId,
          seq: 1,
          dueDate: DateTime(2026, 9, 1),
          amountIdr: 1,
          paidAt: DateTime(2026, 9, 4, 9),
        ).paidOnTime,
        isFalse,
        reason: 'recorded directly after the due date',
      );
    });
  });

  group('seats per slot and the monthly quota', () {
    // A day the sample members have not booked.
    final day = DateTime(2026, 9, 14);
    late LocalSolarRepository solar;
    late Profile admin;
    late List<HubSlot> slots;

    setUp(() async {
      solar = LocalSolarRepository(db, clock);
      admin = await login(SampleSeeder.adminPhone);
      slots = (await snapshots.load(admin)).orderedSlots;
    });

    Future<HubBooking> bookAs(
      String phone,
      HubSlot slot, {
      double kwh = 1,
      double kw = 0.5,
    }) async => solar.book(
      me: await login(phone),
      slotId: slot.id,
      date: day,
      applianceName: 'Oven',
      estKwh: kwh,
      loadKw: kw,
    );

    test('one big booking does not fill the slot', () async {
      await bookAs('081200000002', slots[1], kwh: 4.5, kw: 1.5);
      final a = (await snapshots.load(
        admin,
      )).availabilityOn(day).firstWhere((x) => x.slot.id == slots[1].id);
      expect(a.isFull, isFalse);
      expect(a.bookedMembers, 1);
      expect(a.remainingSeats, kDefaultMembersPerSlot - 1);
      // Another member still gets the same slot.
      final second = await bookAs('081200000003', slots[1]);
      expect(second.status, BookingStatus.booked);
    });

    test('the slot is full after its last seat, for everyone alike', () async {
      await solar.updateHub(
        admin,
        (await snapshots.load(admin)).hub!.copyWith(maxMembersPerSlot: 3),
      );
      await bookAs('081200000002', slots[1]);
      await bookAs('081200000003', slots[1]);
      await bookAs('081200000004', slots[1]);

      await expectLater(
        bookAs('081200000005', slots[1]),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('3 dari 3'),
          ),
        ),
        reason: 'a fourth member has no seat',
      );
      // The next slot is untouched.
      final ok = await bookAs('081200000005', slots[2]);
      expect(ok.status, BookingStatus.booked);

      // Cancelling frees the seat.
      final data = await snapshots.load(admin);
      final first = data.bookings.firstWhere(
        (b) => b.slotId == slots[1].id && sameDay(b.bookingDate, day),
      );
      await solar.setBookingStatus(admin, first.id, BookingStatus.cancelled);
      final late = await bookAs('081200000005', slots[1]);
      expect(late.status, BookingStatus.booked);
    });

    test('a member holds one seat per slot and day', () async {
      await bookAs('081200000002', slots[1]);
      await expectLater(
        bookAs('081200000002', slots[1]),
        throwsA(isA<AppException>()),
      );
      // Other slots are fine.
      expect((await bookAs('081200000002', slots[2])).status, isNotNull);
    });

    test('the hub\'s energy is counted for the day, across slots', () async {
      final hub = (await snapshots.load(admin)).hub!;
      await solar.updateHub(admin, hub.copyWith(dailyCapacityKwh: 5));
      await bookAs('081200000002', slots[0], kwh: 4);
      await expectLater(
        bookAs('081200000003', slots[2], kwh: 2),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('Energi hub'),
          ),
        ),
        reason: 'only 1 kWh is left that day, whichever slot she picks',
      );
      expect((await bookAs('081200000003', slots[2], kwh: 1)).estKwh, 1);
    });

    test('members per slot must be 0–100', () async {
      final hub = (await snapshots.load(admin)).hub!;
      await expectLater(
        solar.updateHub(admin, hub.copyWith(maxMembersPerSlot: 101)),
        throwsA(isA<AppException>()),
      );
      final off = await solar.updateHub(
        admin,
        hub.copyWith(maxMembersPerSlot: 0),
      );
      expect(off.maxMembersPerSlot, 0);
    });

    test('booking, scanning and approval take the session off the month, '
        'and the member is told what is left', () async {
      final clara = await login(SampleSeeder.memberPhone);
      final before = (await snapshots.load(clara)).quotaOf(clara.id, now);

      final booked = await bookRunningSlot(solar, clara, now);
      var q = (await snapshots.load(clara)).quotaOf(clara.id, now);
      expect(q.availableKwh, closeTo(before.availableKwh - 3, 1e-9));
      expect(q.reservedKwh, closeTo(before.reservedKwh + 3, 1e-9));
      expect(q.usedKwh, closeTo(before.usedKwh, 1e-9), reason: 'not used yet');

      final request = await solar.requestConnection(
        me: clara,
        scannedCode: kSolarHubQr,
        applianceName: 'Oven',
        estKwh: 3,
      );
      expect(request.id, booked.id, reason: 'the scan attaches to the booking');
      await solar.respondToConnectionRequest(
        admin: admin,
        bookingId: request.id,
        approve: true,
      );
      await solar.setBookingStatus(admin, request.id, BookingStatus.completed);

      final data = await snapshots.load(clara);
      q = data.quotaOf(clara.id, now);
      expect(q.availableKwh, closeTo(before.availableKwh - 3, 1e-9));
      expect(q.usedKwh, closeTo(before.usedKwh + 3, 1e-9));
      expect(q.reservedKwh, closeTo(before.reservedKwh, 1e-9));
      expect(data.usedOnDayOf(clara.id, now), 3);

      final left = (before.availableKwh - 3).toStringAsFixed(1);
      final told = data
          .notificationsOf(clara.id)
          .firstWhere((n) => n.type == 'hub_connection_approved');
      expect(
        told.body,
        contains('Sisa kuota bulan ini ${left.replaceAll('.', ',')} kWh'),
      );
      expect(told.bodyEn, contains('$left kWh of your quota is left'));
    });

    test('a member cannot mark her own session used; an admin can', () async {
      final clara = await login(SampleSeeder.memberPhone);
      final booked = await bookRunningSlot(solar, clara, now);
      await expectLater(
        solar.setBookingStatus(clara, booked.id, BookingStatus.completed),
        throwsA(isA<AppException>()),
        reason: 'she would be writing her own energy history',
      );
      var q = (await snapshots.load(clara)).quotaOf(clara.id, now);
      final before = q.usedKwh;
      expect(
        (await snapshots.load(clara)).usedOnDayOf(clara.id, now),
        0,
        reason: 'nothing was recorded',
      );

      await solar.setBookingStatus(admin, booked.id, BookingStatus.completed);
      q = (await snapshots.load(clara)).quotaOf(clara.id, now);
      expect(q.usedKwh, closeTo(before + 3, 1e-9));

      // She may still cancel what she booked, but not a finished session.
      final other = await bookAs('081200000003', slots[2]);
      final siti = await login('081200000003');
      await solar.setBookingStatus(siti, other.id, BookingStatus.cancelled);
    });

    test('a rejected scan gives the booked energy back', () async {
      final clara = await login(SampleSeeder.memberPhone);
      final before = (await snapshots.load(clara)).quotaOf(clara.id, now);
      await bookRunningSlot(solar, clara, now);
      final request = await solar.requestConnection(
        me: clara,
        scannedCode: kSolarHubQr,
        applianceName: 'Oven',
        estKwh: 3,
      );
      await solar.respondToConnectionRequest(
        admin: admin,
        bookingId: request.id,
        approve: false,
      );
      final q = (await snapshots.load(clara)).quotaOf(clara.id, now);
      expect(q.availableKwh, closeTo(before.availableKwh, 1e-9));
    });
  });

  group('working hours 07.00–17.00', () {
    LocalSolarRepository at(int hour, [int minute = 0]) =>
        LocalSolarRepository(db, () => DateTime(2026, 9, 11, hour, minute));

    Future<Profile> clara() => login(SampleSeeder.memberPhone);

    test(
      'a scan with no booking is told to book first, within hours',
      () async {
        await expectLater(
          at(9).requestConnection(
            me: await clara(),
            scannedCode: kSolarHubQr,
            applianceName: 'Oven',
            estKwh: 3,
          ),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('Booking slot dulu'),
            ),
          ),
        );
      },
    );

    test('after 17.00 the message is about working hours, not about booking, '
        'in both languages', () async {
      for (final h in [17, 18, 23]) {
        await expectLater(
          at(h).requestConnection(
            me: await clara(),
            scannedCode: kSolarHubQr,
            applianceName: 'Oven',
            estKwh: 3,
          ),
          throwsA(
            isA<AppException>()
                .having(
                  (e) => e.message,
                  'message',
                  allOf(contains('lewat jam kerja'), contains('07.00–17.00')),
                )
                .having((e) => e.en, 'en', contains('closed for the day')),
          ),
          reason: 'at $h.00',
        );
      }
    });

    test('before 07.00 the hub is not open yet', () async {
      await expectLater(
        at(6, 45).requestConnection(
          me: await clara(),
          scannedCode: kSolarHubQr,
          applianceName: 'Oven',
          estKwh: 3,
        ),
        throwsA(
          isA<AppException>()
              .having((e) => e.message, 'message', contains('belum buka'))
              .having((e) => e.en, 'en', contains('open yet')),
        ),
      );
    });

    test('booking for today after closing is refused; tomorrow and booking '
        'before opening are fine', () async {
      final member = await clara();
      final slots = (await snapshots.load(member)).orderedSlots;
      final today = DateTime(2026, 9, 11);
      await expectLater(
        at(17, 30).book(
          me: member,
          slotId: slots.last.id,
          date: today,
          applianceName: 'Oven',
          estKwh: 1,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('lewat jam kerja'),
          ),
        ),
      );
      final tomorrow = await at(17, 30).book(
        me: member,
        slotId: slots.first.id,
        date: DateTime(2026, 9, 14),
        applianceName: 'Oven',
        estKwh: 1,
      );
      expect(tomorrow.status, BookingStatus.booked);
      final early = await at(6, 30).book(
        me: member,
        slotId: slots.last.id,
        date: today,
        applianceName: 'Blender',
        estKwh: 0.5,
      );
      expect(early.status, BookingStatus.booked);
    });
  });

  group('hub load and slots', () {
    test('simultaneous load may not exceed the inverter limit', () async {
      final solar = LocalSolarRepository(db, clock);
      final clara = await login(SampleSeeder.memberPhone);
      final siti = await login('081200000003');
      final data = await snapshots.load(clara);
      final slot = data.orderedSlots[1];
      // A day the sample members have not booked yet (they book today and
      // tomorrow), so only this test's bookings count against the inverter.
      final tomorrow = DateTime(2026, 9, 14);
      // The sample inverter is sized for 15 members; shrink it to a small one.
      await db.update(Tbl.solarHubs, data.hub!.id, {'max_load_kw': 5});

      await solar.book(
        me: clara,
        slotId: slot.id,
        date: tomorrow,
        applianceName: 'Oven',
        estKwh: 1,
        loadKw: 3,
      );

      await expectLater(
        solar.book(
          me: siti,
          slotId: slot.id,
          date: tomorrow,
          applianceName: 'Oven',
          estKwh: 1,
          loadKw: 3,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('Beban serentak'),
          ),
        ),
        reason: '3 kW + 3 kW is over a 5 kW inverter',
      );

      // A lighter load still fits alongside it.
      await solar.book(
        me: siti,
        slotId: slot.id,
        date: tomorrow,
        applianceName: 'Blender',
        estKwh: 1,
        loadKw: 1.5,
      );
      final board = (await snapshots.load(siti)).availabilityOn(tomorrow);
      final a = board.firstWhere((x) => x.slot.id == slot.id);
      expect(a.loadKw, closeTo(4.5, 1e-9));
      expect(a.remainingKw, closeTo(0.5, 1e-9));
    });

    test(
      'scanning the QR for a slot she booked attaches to that booking',
      () async {
        final solar = LocalSolarRepository(db, clock);
        final clara = await login(SampleSeeder.memberPhone);
        final data = await snapshots.load(clara);
        // The test clock is 10.00, inside the 10.00–12.00 slot.
        final slot = data.orderedSlots.firstWhere(
          (x) => x.startHour <= now.hour && now.hour < x.endHour,
        );
        final booked = await solar.book(
          me: clara,
          slotId: slot.id,
          date: dayOf(now),
          applianceName: 'Oven',
          estKwh: 2,
          loadKw: 1.5,
        );
        final before = (await snapshots.load(clara)).bookings.length;

        final request = await solar.requestConnection(
          me: clara,
          scannedCode: kSolarHubQr,
          applianceName: 'Oven',
          estKwh: 9,
          loadKw: 4,
        );

        expect(request.id, booked.id, reason: 'same booking, not a second one');
        expect(request.status, BookingStatus.pendingVerification);
        expect(request.estKwh, 2, reason: 'the booked amount is kept');
        expect(request.requestedAt, isNotNull);
        final after = await snapshots.load(clara);
        expect(after.bookings.length, before);
        expect(after.latestHubRequestOf(clara.id, now)?.id, booked.id);
      },
    );

    test('a plain booking is not shown as a QR request', () async {
      final solar = LocalSolarRepository(db, clock);
      final clara = await login(SampleSeeder.memberPhone);
      final slot = (await snapshots.load(clara)).orderedSlots[3];
      await solar.book(
        me: clara,
        slotId: slot.id,
        date: dayOf(now),
        applianceName: 'Oven',
        estKwh: 1,
        loadKw: 1,
      );
      expect(
        (await snapshots.load(clara)).latestHubRequestOf(clara.id, now),
        isNull,
      );
    });

    test(
      'a closed slot takes no bookings; only an admin can close it',
      () async {
        final solar = LocalSolarRepository(db, clock);
        final admin = await login(SampleSeeder.adminPhone);
        final clara = await login(SampleSeeder.memberPhone);
        final slot = (await snapshots.load(clara)).orderedSlots[2];

        await expectLater(
          solar.setSlotOpen(clara, slot.id, false),
          throwsA(isA<AppException>()),
          reason: 'members cannot close slots',
        );

        await solar.setSlotOpen(admin, slot.id, false);
        await expectLater(
          solar.book(
            me: clara,
            slotId: slot.id,
            date: DateTime(2026, 9, 14),
            applianceName: 'Oven',
            estKwh: 1,
          ),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('ditutup'),
            ),
          ),
        );

        await solar.setSlotOpen(admin, slot.id, true);
        await solar.book(
          me: clara,
          slotId: slot.id,
          date: DateTime(2026, 9, 14),
          applianceName: 'Oven',
          estKwh: 1,
        );
      },
    );
  });
}
