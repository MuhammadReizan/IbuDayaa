import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/app/app.dart';
import 'package:ibudaya/core/demo/demo_providers.dart';

import '../support/demo_seed.dart';

/// Route smoke tests for the demo golden path. These would have caught the
/// route-name-vs-location bugs: passing a name constant to `context.push` /
/// `context.go` throws / mis-navigates, failing the assertions below.
void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoScenarioProvider.overrideWith((ref) => demoSeedScenario()),
        ],
        child: const IbuDayaApp(),
      ),
    );
    await tester.pump(); // splash resolves
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  /// Pump past a simulated scan / submit delay without calling pumpAndSettle
  /// (the LoadingState spinner never settles).
  Future<void> pumpPastDelay(
    WidgetTester tester, [
    Duration d = const Duration(milliseconds: 1400),
  ]) async {
    await tester.pump();
    await tester.pump(d);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  testWidgets('boots to Home with the four-tab shell', (tester) async {
    await pumpApp(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.textContaining('Ibu Clara'), findsWidgets);
  });

  testWidgets('Home quick action "Simulasi Pembiayaan" opens the real '
      'financing input flow (not the removed stub)', (tester) async {
    await pumpApp(tester);
    await tapText(tester, 'Simulasi\nPembiayaan');

    // Real screen: has a "Hitung Simulasi" CTA; stub only had "hadir segera".
    expect(find.text('Hitung Simulasi'), findsOneWidget);
    expect(find.textContaining('hadir segera'), findsNothing);
  });

  testWidgets('scan → analysis → solar booking', (tester) async {
    await pumpApp(tester);

    await tapText(tester, 'Scan\nTagihan');
    expect(find.text('Ambil Foto Tagihan'), findsOneWidget);

    await tester.tap(find.text('Ambil Foto Tagihan'));
    await pumpPastDelay(tester);

    // Product-honesty rename applied.
    expect(find.text('Analisis Energi'), findsOneWidget);
    expect(find.text('Analisis AI Energi'), findsNothing);

    await tester.tap(find.text('Lihat Jadwal Solar Hub'));
    await tester.pumpAndSettle();
    expect(find.text('Booking Solar Hub'), findsOneWidget);
  });

  testWidgets('Solar Hub tab → radar → booking → confirmation → Home', (
    tester,
  ) async {
    await pumpApp(tester);

    // Switch to the Solar Hub tab via the bottom navigation bar.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Solar Hub'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan Sekarang'));
    await pumpPastDelay(tester);
    expect(find.text('Radar Atap'), findsOneWidget);

    await tester.tap(find.text('Lanjut ke Rekomendasi Solar Hub'));
    await tester.pumpAndSettle();
    expect(find.text('Booking Solar Hub'), findsOneWidget);

    // Pick an appliance and an open slot (both may be below the fold).
    await tester.ensureVisible(find.text('Oven'));
    await tester.tap(find.text('Oven'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('10.00–12.00'));
    await tester.tap(find.text('10.00–12.00'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Booking Sekarang'));
    await tester.tap(find.text('Booking Sekarang'));
    await pumpPastDelay(tester, const Duration(milliseconds: 400));
    expect(find.text('Booking Terkonfirmasi'), findsOneWidget);

    await tester.ensureVisible(find.text('Kembali ke Beranda'));
    await tester.tap(find.text('Kembali ke Beranda'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.textContaining('Ibu Clara'), findsWidgets);
  });

  testWidgets('Credit Score → Financing simulation', (tester) async {
    await pumpApp(tester);

    await tapText(tester, 'Lihat Detail'); // on the Skor Kredit Energi tile
    expect(find.text('Faktor Penentu Skor Anda'), findsOneWidget);

    await tester.tap(find.text('Lihat Simulasi Pembiayaan'));
    await tester.pumpAndSettle();
    expect(find.text('Hitung Simulasi'), findsOneWidget);
  });

  testWidgets(
    'Pesan tab lists the seeded threads (not blank / not empty state)',
    (tester) async {
      await pumpApp(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Pesan'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Pesan'), findsNothing);
      expect(find.text('Solar Hub Admin'), findsOneWidget);
      expect(find.text('Tips IbuDaya'), findsOneWidget);
    },
  );

  testWidgets('Arisan → Bursa Kuota', (tester) async {
    await pumpApp(tester);
    await tapText(tester, 'Arisan\nEnergi');
    expect(find.text('Jadwal Giliran (Bulan Ini)'), findsOneWidget);

    await tester.tap(find.text('Tukar & Bagikan Kuota'));
    await tester.pumpAndSettle();
    expect(find.text('Penawaran dari Komunitas'), findsOneWidget);
  });
}
