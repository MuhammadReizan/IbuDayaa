import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ibudaya/core/hub_qr.dart';
import 'package:ibudaya/app/app.dart';
import 'package:ibudaya/app/router.dart';
import 'package:ibudaya/core/db/local_database.dart';
import 'package:ibudaya/core/models/models.dart';
import 'package:ibudaya/core/paths.dart';
import 'package:ibudaya/core/repositories/local/local_auth_repository.dart';
import 'package:ibudaya/core/repositories/local/local_snapshot_repository.dart';
import 'package:ibudaya/core/repositories/local/sample_seeder.dart';
import 'package:ibudaya/core/state/actions.dart';
import 'package:ibudaya/core/state/app_state.dart';
import 'package:ibudaya/core/state/selectors.dart';
import 'package:ibudaya/features/credit_score/data/rule_based_credit_scoring_engine.dart';
import 'package:ibudaya/features/home/member_home_screen.dart';

final _now = DateTime(2026, 9, 11, 10);
DateTime _clock() => _now;

/// Boots the real app on an in-memory database holding the sample
/// cooperative, optionally already signed in.
Future<void> pumpApp(
  WidgetTester tester, {
  String? signedInAs,
  Size size = const Size(412, 915),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final db = await LocalDatabase.open(MemoryDbStorage());
  await SampleSeeder(db, _clock, const RuleBasedCreditScoringEngine()).seed();
  var initial = const AppState();
  if (signedInAs != null) {
    final me = await LocalAuthRepository(
      db,
      _clock,
    ).login(phone: signedInAs, pin: SampleSeeder.pin);
    initial = await loadAppState(LocalSnapshotRepository(db, _clock), me);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(_clock),
        initialAppStateProvider.overrideWithValue(initial),
      ],
      child: const IbuDayaApp(),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter routerOf(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(IbuDayaApp)),
).read(routerProvider);

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(IbuDayaApp)));

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text).last;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('member signs in with phone and PIN pad', (tester) async {
    await pumpApp(tester);
    expect(find.text('Masuk'), findsOneWidget);

    await tapText(tester, 'Masuk');
    await tester.enterText(
      find.byType(TextFormField),
      SampleSeeder.memberPhone,
    );
    await tapText(tester, 'Lanjut');

    for (final d in SampleSeeder.pin.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Halo, Ibu Clara'), findsOneWidget);
    expect(find.text('Status Penggunaan Daya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wrong PIN says how many tries are left', (tester) async {
    await pumpApp(tester);
    await tapText(tester, 'Masuk');
    await tester.enterText(
      find.byType(TextFormField),
      SampleSeeder.memberPhone,
    );
    await tapText(tester, 'Lanjut');
    for (final d in '258147'.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.textContaining('Sisa percobaan'), findsOneWidget);
  });

  testWidgets('records come only from the hub and feed the analysis', (
    tester,
  ) async {
    await pumpApp(tester, signedInAs: SampleSeeder.memberPhone);
    routerOf(tester).go(Paths.memberRecords);
    await tester.pumpAndSettle();

    expect(find.text('Tambah manual'), findsNothing);
    expect(
      find.textContaining('Dicatat otomatis oleh Solar Hub'),
      findsOneWidget,
    );
    expect(find.textContaining('Token'), findsNothing);

    routerOf(tester).push(Paths.energyAnalysis);
    await tester.pumpAndSettle();
    expect(find.text('Analisis Energi'), findsOneWidget);
    expect(find.text('Oven'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('push → save → pop keeps earlier screens healthy', (
    tester,
  ) async {
    await pumpApp(tester, signedInAs: SampleSeeder.memberPhone);

    await tapText(tester, 'Alat Usaha');
    await tapText(tester, 'Tambah alat');
    await tapText(tester, 'Blender');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Blender'),
      'Blender Kedua',
    );
    await tapText(tester, 'Simpan');

    expect(find.text('Blender Kedua'), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    // The home list was scrolled to reach the shortcut, so check the route
    // and the screen rather than its first row.
    expect(
      routerOf(tester).routerDelegate.currentConfiguration.uri.path,
      Paths.memberHome,
    );
    expect(find.byType(MemberHomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin reviews, approves and disburses a loan', (tester) async {
    await pumpApp(tester, signedInAs: SampleSeeder.adminPhone);
    expect(find.text('Dasbor Admin'), findsOneWidget);

    await tester.tap(find.text('Pengajuan'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Siti Rahma');
    expect(find.text('Review Pengajuan'), findsOneWidget);

    await tapText(tester, 'Mulai review');
    expect(find.text('Sedang direview'), findsOneWidget);

    await tapText(tester, 'Setujui');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Setujui'),
      ),
    );
    await tester.pumpAndSettle();
    // Status pill and the timeline entry.
    expect(find.text('Disetujui admin'), findsWidgets);

    await tapText(tester, 'Catat dana dicairkan');
    await tapText(tester, 'Ya, sudah dicairkan');
    expect(find.text('Dana dicairkan'), findsWidgets);
    expect(find.text('Cicilan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a member cannot reach admin screens', (tester) async {
    await pumpApp(tester, signedInAs: SampleSeeder.memberPhone);
    routerOf(tester).go(Paths.adminSettings);
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan Koperasi'), findsNothing);
    expect(find.text('Halo, Ibu Clara'), findsOneWidget);
  });

  testWidgets(
    'QR connection request → admin approves → completed session records electricity automatically',
    (tester) async {
      await pumpApp(tester, signedInAs: SampleSeeder.adminPhone);
      final container = containerOf(tester);
      final actions = container.read(actionsProvider);

      final clara = container
          .read(appStateProvider)
          .data
          .members
          .firstWhere((m) => m.fullName == 'Ibu Clara');

      await actions.login(SampleSeeder.memberPhone, SampleSeeder.pin);
      final request = await actions.requestConnection(
        scannedCode: kSolarHubQr,
        applianceName: 'Oven',
        estKwh: 3,
      );
      expect(request.status, BookingStatus.pendingVerification);

      final before = container
          .read(appStateProvider)
          .data
          .recordsOf(clara.id)
          .where((r) => r.source == RecordSource.hub)
          .length;

      await actions.login(SampleSeeder.adminPhone, SampleSeeder.pin);
      expect(
        container.read(appStateProvider).data.hubRequests.map((b) => b.id),
        contains(request.id),
      );
      await actions.respondToConnectionRequest(request.id, approve: true);
      final approved = container
          .read(appStateProvider)
          .data
          .bookings
          .firstWhere((b) => b.id == request.id);
      // Approval starts the supply, so the session is recorded right away.
      expect(approved.status, BookingStatus.completed);
      final after = container
          .read(appStateProvider)
          .data
          .recordsOf(clara.id)
          .where((r) => r.source == RecordSource.hub)
          .toList();
      expect(after.length, before + 1);
      final created = after.firstWhere((r) => r.bookingId == request.id);
      expect(created.kwh, 3);

      // Back on the member's account the request reads as verified.
      await actions.login(SampleSeeder.memberPhone, SampleSeeder.pin);
      final shown = container
          .read(appStateProvider)
          .data
          .latestHubRequestOf(clara.id, container.read(clockProvider)());
      expect(shown?.id, request.id);
      expect(shown?.status, BookingStatus.completed);
      expect(tester.takeException(), isNull);
    },
  );
}
