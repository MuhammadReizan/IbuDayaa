import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/app/app.dart';
import 'package:ibudaya/core/data/app_data.dart';
import 'package:ibudaya/core/data/app_data_controller.dart';
import 'package:ibudaya/core/data/app_store.dart';
import 'package:ibudaya/core/data/sample_data.dart';

import '../support/fixtures.dart';

void main() {
  Future<void> boot(WidgetTester tester, {AppData? seed}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStoreProvider.overrideWithValue(
            MemoryAppStore(seed ?? AppData.empty),
          ),
        ],
        child: const IbuDayaApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  testWidgets('a fresh install lands on onboarding, not a dashboard', (
    tester,
  ) async {
    await boot(tester);

    expect(find.text('Selamat datang di IbuDaya'), findsOneWidget);
    // No bottom nav until there is a profile.
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('onboarding creates the profile and persists it', (tester) async {
    await boot(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Misal: Ibu Sari'),
      'Ibu Rina',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Misal: Katering Sari Rasa'),
      'Warung Rina',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Misal: Palembang'),
      'Medan',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Mulai Pakai IbuDaya'));
    await tester.tap(find.text('Mulai Pakai IbuDaya'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.textContaining('Ibu Rina'), findsWidgets);
    expect(find.text('Warung Rina'), findsWidgets);
  });

  testWidgets('an onboarded user with no records is asked for a bill, '
      'not shown fake numbers', (tester) async {
    await boot(tester, seed: AppData(profile: testProfile()));

    expect(find.text('Mulai dari tagihan pertama'), findsOneWidget);
    // No invented rupiah hero on an empty account.
    expect(find.textContaining('Rp 245.000'), findsNothing);
  });

  testWidgets('recording a bill updates the dashboard and survives a reload', (
    tester,
  ) async {
    final store = MemoryAppStore(AppData(profile: testProfile(tariff: 1000)));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appStoreProvider.overrideWithValue(store)],
        child: const IbuDayaApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catat Tagihan Pertama'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Misal: 128'),
      '120',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Misal: 185000'),
      '120000',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // The written document is what a relaunch would read back.
    final persisted = await store.load();
    expect(persisted.bills.single.kwh, 120);
    expect(persisted.bills.single.totalIdr, 120000);
  });

  testWidgets('the score withholds a number until there is enough history', (
    tester,
  ) async {
    await boot(
      tester,
      seed: AppData(
        profile: testProfile(),
        bills: [testBill(id: 'b0', monthsAgo: 0, kwh: 100)],
      ),
    );

    await tester.ensureVisible(find.text('Lihat'));
    await tester.tap(find.text('Lihat'));
    await tester.pumpAndSettle();

    expect(find.text('Belum cukup data'), findsOneWidget);
    expect(find.text('Faktor Penentu Skor Anda'), findsNothing);
  });

  testWidgets('sample data produces a score with its four factors', (
    tester,
  ) async {
    await boot(tester, seed: buildSampleData(testProfile()));

    await tester.ensureVisible(find.text('Lihat Detail'));
    await tester.tap(find.text('Lihat Detail'));
    await tester.pumpAndSettle();

    expect(find.text('Faktor Penentu Skor Anda'), findsOneWidget);
    expect(find.text('Belum cukup data'), findsNothing);
    expect(find.textContaining('bukan skor BI Checking'), findsOneWidget);
  });

  testWidgets('the financing screen calculates but never offers a loan', (
    tester,
  ) async {
    await boot(tester, seed: buildSampleData(testProfile()));

    final action = find.text('Hitung\nCicilan');
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.text('IbuDaya bukan pemberi pinjaman'), findsOneWidget);
    for (final banned in ['Ajukan', 'Pengajuan', 'Disetujui', 'disetujui']) {
      expect(
        find.textContaining(banned),
        findsNothing,
        reason: 'financing must never use "$banned"',
      );
    }
  });

  testWidgets('the shell has no Pesan tab it cannot deliver', (tester) async {
    await boot(tester, seed: AppData(profile: testProfile()));

    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Solar Hub'), findsWidgets);
    expect(find.text('Arisan'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);
    expect(find.text('Pesan'), findsNothing);
  });
}
