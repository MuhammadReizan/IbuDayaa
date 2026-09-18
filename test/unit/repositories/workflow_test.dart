import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/hub_qr.dart';
import 'package:ibudaya/core/db/local_database.dart';
import 'package:ibudaya/core/db/row.dart';
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

  test('sample cooperative seeds once and nobody stays signed in', () async {
    expect(await auth.restoreSession(), isNull);
    await SampleSeeder(db, clock, engine).seed();
    final admin = await login(SampleSeeder.adminPhone);
    final data = await snapshots.load(admin);
    expect(data.memberProfiles, hasLength(4));
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
    final tomorrow = DateTime(2026, 9, 12);
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
        slotId: slot.id,
        date: tomorrow,
        applianceName: 'Oven',
        estKwh: 500,
      ),
      throwsA(isA<AppException>()),
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
          estKwh: availability.remainingKwh + 10,
        ),
        throwsA(isA<AppException>()),
        reason: 'the pending request already reserved part of this slot',
      );
    },
  );

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
    "a member's own hub allocation overrides the cooperative default",
    () async {
      final solar = LocalSolarRepository(db, clock);
      final admin = await login(SampleSeeder.adminPhone);
      var clara = await login(SampleSeeder.memberPhone);
      final existingBooked = (await snapshots.load(
        clara,
      )).quotaOf(clara.id, now).bookedKwh;
      final tomorrow = DateTime(2026, 9, 12);
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

      expect(kpis.members, 4);
      expect(kpis.activeMembers, greaterThan(0));
      expect(kpis.activeMembers, lessThanOrEqualTo(kpis.members));
      expect(kpis.loanReady, lessThanOrEqualTo(kpis.members));
      expect(kpis.installmentsOnTime, lessThanOrEqualTo(kpis.installmentsDue));
      // Nothing is due before a loan is disbursed, and no rate is invented.
      expect(kpis.installmentsDue, 0);
      expect(kpis.onTimePct, isNull);
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

  group('hub load and slots', () {
    test('simultaneous load may not exceed the inverter limit', () async {
      final solar = LocalSolarRepository(db, clock);
      final clara = await login(SampleSeeder.memberPhone);
      final siti = await login('081200000003');
      final slot = (await snapshots.load(clara)).orderedSlots[1];
      final tomorrow = DateTime(2026, 9, 12);

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
        reason: '3 kW + 3 kW is over the 5 kW sample inverter',
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
            date: DateTime(2026, 9, 12),
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
          date: DateTime(2026, 9, 12),
          applianceName: 'Oven',
          estKwh: 1,
        );
      },
    );
  });
}
