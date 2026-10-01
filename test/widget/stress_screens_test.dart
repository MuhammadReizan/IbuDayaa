// Opens every screen in the states a real person meets and that the sample
// cooperative never shows: a brand-new cooperative with nothing in it, a
// cooperative whose admin has only just configured the hub, and every state
// again with large text. A screen that crashes or overflows names itself.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ibudaya/app/app.dart';
import 'package:ibudaya/app/router.dart';
import 'package:ibudaya/core/db/ids.dart';
import 'package:ibudaya/core/db/local_database.dart';
import 'package:ibudaya/core/db/tables.dart';
import 'package:ibudaya/core/l10n/l10n.dart';
import 'package:ibudaya/core/models/models.dart';
import 'package:ibudaya/core/paths.dart';
import 'package:ibudaya/core/repositories/local/local_auth_repository.dart';
import 'package:ibudaya/core/repositories/local/local_snapshot_repository.dart';
import 'package:ibudaya/core/repositories/local/sample_seeder.dart';
import 'package:ibudaya/core/state/app_state.dart';
import 'package:ibudaya/features/credit_score/data/rule_based_credit_scoring_engine.dart';

final _now = DateTime(2026, 10, 1, 9, 30);
DateTime _clock() => _now;

class _FixedLocale extends LocaleNotifier {
  _FixedLocale(this.locale);
  final Locale locale;

  @override
  Future<Locale> build() async => locale;
}

const _pin = '147258';

/// A cooperative with only its admin.
Future<LocalDatabase> _fresh() async {
  final db = await LocalDatabase.open(MemoryDbStorage());
  await LocalAuthRepository(db, _clock).registerAdmin(
    phone: '081311110001',
    pin: _pin,
    fullName: 'Admin Baru',
    city: 'Palembang',
    cooperativeName: 'Koperasi Baru',
  );
  return db;
}

/// The admin has set the hub; one member joined and registered one appliance
/// but has not used the hub yet.
Future<LocalDatabase> _configured() async {
  final db = await _fresh();
  final auth = LocalAuthRepository(db, _clock);
  final coop = Cooperative.fromRow(db.select(Tbl.cooperatives).single);
  await db.update(
    Tbl.solarHubs,
    db.select(Tbl.solarHubs).single['id'] as String,
    {'daily_capacity_kwh': 17.5, 'max_load_kw': 5},
  );
  final m = await auth.registerMember(
    phone: '081311110002',
    pin: _pin,
    fullName: 'Anggota Baru',
    businessName: 'Usaha Baru',
    city: 'Palembang',
    inviteCode: coop.inviteCode,
  );
  await db.insert(
    Tbl.appliances,
    Appliance(
      id: newId(),
      userId: m.id,
      name: 'Blender',
      kind: 'blender',
      watts: 350,
      hoursPerDay: 1,
      daysPerWeek: 5,
      createdAt: _now,
    ).toRow(),
  );
  return db;
}

Future<LocalDatabase> _sample() async {
  final db = await LocalDatabase.open(MemoryDbStorage());
  await SampleSeeder(db, _clock, const RuleBasedCreditScoringEngine()).seed();
  return db;
}

Future<void> _pump(
  WidgetTester tester,
  LocalDatabase db, {
  required String phone,
  required Locale locale,
  required double textScale,
  String pin = _pin,
}) async {
  tester.view.physicalSize = const Size(360, 780) * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  final me = await LocalAuthRepository(
    db,
    _clock,
  ).login(phone: phone, pin: pin);
  final initial = await loadAppState(LocalSnapshotRepository(db, _clock), me);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(_clock),
        initialAppStateProvider.overrideWithValue(initial),
        localeProvider.overrideWith(() => _FixedLocale(locale)),
      ],
      child: const IbuDayaApp(),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _router(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(IbuDayaApp)),
).read(routerProvider);

const _memberPaths = [
  Paths.memberHome,
  Paths.memberSolar,
  Paths.memberMessages,
  Paths.memberProfile,
  Paths.memberRecords,
  Paths.score,
  Paths.creditReport,
  Paths.loanApply,
  Paths.loans,
  Paths.installments,
  Paths.arisan,
  Paths.quota,
  Paths.quotaNew,
  Paths.energyAnalysis,
  Paths.energy,
  Paths.booking,
  Paths.bookings,
  Paths.appliances,
  Paths.applianceEdit,
  Paths.roof,
  Paths.notifications,
  Paths.profileEdit,
  Paths.changePin,
  Paths.language,
  Paths.about,
];

const _adminPaths = [
  Paths.adminHome,
  Paths.adminLoans,
  Paths.adminMembers,
  Paths.adminMore,
  Paths.adminPayments,
  Paths.adminInstallments,
  Paths.adminArisan,
  Paths.adminArisanNew,
  Paths.adminHub,
  Paths.adminHubRequests,
  Paths.adminHubBoard,
  Paths.adminSummary,
  Paths.adminSettings,
  Paths.adminAnnounce,
  Paths.adminMessages,
  Paths.notifications,
  Paths.profileEdit,
  Paths.changePin,
  Paths.language,
  Paths.about,
];

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  final states =
      <
        String,
        ({Future<LocalDatabase> Function() make, String admin, String member})
      >{
        'brand-new cooperative': (
          make: _fresh,
          admin: '081311110001',
          member: '',
        ),
        'configured, member has not used the hub': (
          make: _configured,
          admin: '081311110001',
          member: '081311110002',
        ),
        'sample cooperative': (
          make: _sample,
          admin: SampleSeeder.adminPhone,
          member: SampleSeeder.memberPhone,
        ),
      };

  for (final entry in states.entries) {
    for (final (locale, scale) in [
      (const Locale('id'), 1.0),
      (const Locale('en'), 1.3),
    ]) {
      final label = '${entry.key} · ${locale.languageCode} · ×$scale';
      final s = entry.value;

      for (final path in _adminPaths) {
        testWidgets('admin $path — $label', (tester) async {
          final db = await s.make();
          await _pump(
            tester,
            db,
            phone: s.admin,
            locale: locale,
            textScale: scale,
            pin: s.admin == SampleSeeder.adminPhone ? SampleSeeder.pin : _pin,
          );
          _router(tester).go(path);
          await tester.pumpAndSettle();
        });
      }

      if (s.member.isEmpty) continue;
      for (final path in _memberPaths) {
        testWidgets('member $path — $label', (tester) async {
          final db = await s.make();
          await _pump(
            tester,
            db,
            phone: s.member,
            locale: locale,
            textScale: scale,
            pin: s.member == SampleSeeder.memberPhone ? SampleSeeder.pin : _pin,
          );
          _router(tester).go(path);
          await tester.pumpAndSettle();
        });
      }
    }
  }
}
