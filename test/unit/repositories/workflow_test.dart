import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/db/local_database.dart';
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
}
