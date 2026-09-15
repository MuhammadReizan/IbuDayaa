import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/app/app.dart';
import 'package:ibudaya/app/router.dart';
import 'package:ibudaya/core/db/local_database.dart';
import 'package:ibudaya/core/demo/demo_analysis_repository.dart';
import 'package:ibudaya/core/demo/demo_bill_repository.dart';
import 'package:ibudaya/core/paths.dart';
import 'package:ibudaya/core/repositories/local/local_auth_repository.dart';
import 'package:ibudaya/core/repositories/local/local_snapshot_repository.dart';
import 'package:ibudaya/core/repositories/local/sample_seeder.dart';
import 'package:ibudaya/core/state/app_state.dart';
import 'package:ibudaya/features/credit_score/data/rule_based_credit_scoring_engine.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

final _now = DateTime(2026, 9, 11, 10);
DateTime _clock() => _now;

Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 915) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final db = await LocalDatabase.open(MemoryDbStorage());
  await SampleSeeder(db, _clock, const RuleBasedCreditScoringEngine()).seed();
  final me = await LocalAuthRepository(
    db,
    _clock,
  ).login(phone: SampleSeeder.memberPhone, pin: SampleSeeder.pin);
  final initial = await loadAppState(LocalSnapshotRepository(db, _clock), me);

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

void main() {
  setUp(() {
    DemoAnalysisRepository.clear();
  });

  tearDown(() {
    DemoAnalysisRepository.clear();
  });

  testWidgets('unknown barcode shows snackbar and does not navigate', (
    tester,
  ) async {
    await pumpApp(tester);

    final router = ProviderScope.containerOf(
      tester.element(find.byType(IbuDayaApp)),
    ).read(routerProvider);

    router.push(Paths.scanDemo);
    await tester.pumpAndSettle();

    final scannerFinder = find.byType(MobileScanner);
    expect(scannerFinder, findsOneWidget);
    final scannerWidget = tester.widget<MobileScanner>(scannerFinder);

    scannerWidget.onDetect!(
      const BarcodeCapture(
        barcodes: [Barcode(rawValue: 'UNKNOWN-RANDOM-BARCODE')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ini bukan barcode demo IbuDaya.'), findsWidgets);
    expect(DemoAnalysisRepository.current, isNull);
    expect(find.byType(MobileScanner), findsOneWidget);
  });

  testWidgets(
    'a leftover analysis from an earlier scan never leaks into a new one',
    (tester) async {
      // Regression test: DemoAnalysisRepository.current used to only be
      // cleared by the analysis screen's explicit back button, so a member
      // who left that screen any other way (hardware back, a bottom-nav
      // tap) kept the previous scan's result in memory. A fresh scan
      // attempt must discard it up front, even when that new attempt
      // itself fails to match anything.
      await pumpApp(tester);
      DemoAnalysisRepository.current = DemoBillRepository.findByBarcode(
        'IBUDAYA-DEMO-001',
      )!.analysis;
      expect(DemoAnalysisRepository.current, isNotNull);

      final router = ProviderScope.containerOf(
        tester.element(find.byType(IbuDayaApp)),
      ).read(routerProvider);

      router.push(Paths.scanDemo);
      await tester.pumpAndSettle();

      final scannerWidget = tester.widget<MobileScanner>(
        find.byType(MobileScanner),
      );
      scannerWidget.onDetect!(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'UNKNOWN-RANDOM-BARCODE')],
        ),
      );
      await tester.pumpAndSettle();

      expect(DemoAnalysisRepository.current, isNull);
    },
  );

  testWidgets('IBUDAYA-DEMO-001 opens Analisis Energi with Energy Spike data', (
    tester,
  ) async {
    await pumpApp(tester);

    final router = ProviderScope.containerOf(
      tester.element(find.byType(IbuDayaApp)),
    ).read(routerProvider);

    router.push(Paths.scanDemo);
    await tester.pumpAndSettle();

    final scannerFinder = find.byType(MobileScanner);
    final scannerWidget = tester.widget<MobileScanner>(scannerFinder);

    scannerWidget.onDetect!(
      const BarcodeCapture(barcodes: [Barcode(rawValue: 'IBUDAYA-DEMO-001')]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lonjakan Energi Terdeteksi'), findsOneWidget);
    expect(find.text('Pemakaian tinggi jam 18.00–21.00'), findsOneWidget);
    expect(find.textContaining('45.026'), findsWidgets);
    expect(find.text('Kulkas'), findsWidgets);
  });

  testWidgets('IBUDAYA-DEMO-002 opens Analisis Energi with Normal Usage data', (
    tester,
  ) async {
    await pumpApp(tester);

    final router = ProviderScope.containerOf(
      tester.element(find.byType(IbuDayaApp)),
    ).read(routerProvider);

    router.push(Paths.scanDemo);
    await tester.pumpAndSettle();

    final scannerFinder = find.byType(MobileScanner);
    final scannerWidget = tester.widget<MobileScanner>(scannerFinder);

    scannerWidget.onDetect!(
      const BarcodeCapture(barcodes: [Barcode(rawValue: 'IBUDAYA-DEMO-002')]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pemakaian Stabil'), findsOneWidget);
    expect(find.textContaining('162.000'), findsWidgets);
    expect(find.text('Kipas Angin'), findsWidgets);
  });

  testWidgets(
    'IBUDAYA-DEMO-003 opens Analisis Energi with Solar Recommendation',
    (tester) async {
      await pumpApp(tester);

      final router = ProviderScope.containerOf(
        tester.element(find.byType(IbuDayaApp)),
      ).read(routerProvider);

      router.push(Paths.scanDemo);
      await tester.pumpAndSettle();

      final scannerFinder = find.byType(MobileScanner);
      final scannerWidget = tester.widget<MobileScanner>(scannerFinder);

      scannerWidget.onDetect!(
        const BarcodeCapture(barcodes: [Barcode(rawValue: 'IBUDAYA-DEMO-003')]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Potensi Penghematan Ditemukan'), findsOneWidget);
      expect(find.textContaining('120.000'), findsWidgets);
      expect(find.text('Oven'), findsWidgets);
    },
  );
}
