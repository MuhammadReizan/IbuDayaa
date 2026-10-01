// With the app set to English, every screen must read as English: no stray
// Indonesian sentences from a hard-coded string. Sample data the demo seeds
// (people's names, businesses, chat lines) is content, not interface text.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ibudaya/core/hub_qr.dart';
import 'package:ibudaya/core/design/components/components.dart';
import 'package:ibudaya/core/state/actions.dart';
import 'package:ibudaya/core/l10n/l10n.dart';
import 'package:ibudaya/core/paths.dart';
import 'package:ibudaya/core/repositories/local/sample_seeder.dart';

import 'app_flow_test.dart' show containerOf, pumpApp, routerOf;

final _indonesian = RegExp(
  r'\b(yang|dan|untuk|anda|belum|sudah|bulan|tidak|dengan|pada|atau|'
  r'koperasi|anggota|pinjaman|kuota|iuran|setoran|pengajuan|catatan|skor|'
  r'alat|usaha|listrik|pemakaian|hubungi|silakan|hari|jam|lunas|ditolak|'
  r'disetujui|terkirim|pilih|isi|kembali|jatah|sesi|kursi|cicilan|tersisa|'
  r'terpakai|dipesan|konfirmasi|tolak|bayar|pembayaran|sisa|lagi|masuk|'
  r'keluar|simpan|batal|hapus|tambah|kirim|tanggal|jumlah|nama|harga|tarif|'
  r'kapasitas|energi|jadwal|waktu|dibagikan|diterima|mohon|berhasil|gagal|'
  r'lengkap|ubah|pengaturan|bantuan|tentang|beranda)\b',
  caseSensitive: false,
);

/// English function words that must not appear on an Indonesian screen.
final _english = RegExp(
  r'\b(the|your|you|with|from|this|that|will|have|remaining|please|enter|'
  r'choose|already|installment|installments|allowance|seats|booked|left|'
  r'confirm|reject|approve|received|shared|overdue|awaiting|loan|payment)\b',
  caseSensitive: false,
);

/// Demo content written in Indonesian on purpose.
const _sampleContent = [
  'Koperasi Energi Melati',
  'Solar Hub Balai Melati',
  'Balai Warga',
  'Arisan Digital Melati',
  'Katering Clara',
  'Jahit Siti',
  'Kue Basah Lina',
  'Warung Putri',
  'Sisa kuota',
  'Saya tidak produksi',
  'Ada pesanan kue',
  'Untuk kebutuhan katering',
  'Untuk mesin obras',
  'Selamat pagi ibu-ibu',
  'Siap Bu',
  'Minggu ini saya',
  'Timbangan Digital',
  'Mesin Jahit',
  'Kulkas',
  'Pesanan songket',
  'Untuk pesanan kue',
  'Bulan ini produksi',
  'Musim hajatan',
  'Saya butuh tambahan',
  'Kuota saya sisa',
  'Terima kasih Bu Dewi',
  'Bu, jadwal slot',
  'Usaha stabil',
  'Stok ikan',
  'Nominal yang masuk',
  'Untuk freezer',
  'Untuk memperbaiki',
  'Stok kain',
  'Stok bahan kue',
  'Bu Lina, iuran',
  'Maaf Bu',
  'Kuota saya masih banyak',
];

/// Every piece of text a person can read: Text widgets, field labels and hints,
/// tooltips (button hints and back arrows).
Iterable<String> _visibleTexts(WidgetTester tester) sync* {
  for (final t in tester.widgetList<Text>(find.byType(Text))) {
    yield (t.data ?? t.textSpan?.toPlainText() ?? '').trim();
  }
  for (final d in tester.widgetList<InputDecorator>(
    find.byType(InputDecorator),
  )) {
    final dec = d.decoration;
    for (final s in [
      dec.labelText,
      dec.hintText,
      dec.helperText,
      dec.errorText,
    ]) {
      if (s != null) yield s.trim();
    }
  }
  for (final t in tester.widgetList<Tooltip>(find.byType(Tooltip))) {
    final m = t.message;
    if (m != null) yield m.trim();
  }
}

List<String> _offenders(WidgetTester tester, [RegExp? wrong]) {
  final pattern = wrong ?? _indonesian;
  final out = <String>[];
  for (final s in _visibleTexts(tester)) {
    if (s.isEmpty || !pattern.hasMatch(s)) continue;
    if (identical(pattern, _indonesian) && _sampleContent.any(s.contains)) {
      continue;
    }
    out.add(s);
  }
  return out;
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  const english = Locale('en');

  testWidgets('English is really in use on the home screen', (tester) async {
    await pumpApp(
      tester,
      signedInAs: SampleSeeder.memberPhone,
      size: const Size(360, 780),
      locale: english,
    );
    expect(find.text('Hello, Ibu Clara'), findsOneWidget);
    expect(find.text('Halo, Ibu Clara'), findsNothing);
  });

  testWidgets('the same check does catch Indonesian interface text', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signedInAs: SampleSeeder.memberPhone,
      size: const Size(360, 780),
      locale: const Locale('id', 'ID'),
    );
    expect(find.text('Halo, Ibu Clara'), findsOneWidget);
    expect(_offenders(tester), isNotEmpty);
  });

  testWidgets('switching the language changes open screens at once, and '
      'back again', (tester) async {
    await pumpApp(
      tester,
      signedInAs: SampleSeeder.memberPhone,
      size: const Size(360, 780),
    );
    final container = containerOf(tester);
    expect(find.text('Halo, Ibu Clara'), findsOneWidget);

    // The notifier sets its state first and then writes the preference file;
    // that real file write cannot finish inside a widget test's fake clock.
    unawaited(container.read(localeProvider.notifier).setLocale(english));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Ibu Clara'), findsOneWidget);
    expect(_offenders(tester), isEmpty);

    unawaited(
      container
          .read(localeProvider.notifier)
          .setLocale(const Locale('id', 'ID')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Halo, Ibu Clara'), findsOneWidget);
  });

  for (final (locale, expected) in [
    (english, 'Book a slot first before scanning the QR'),
    (const Locale('id', 'ID'), 'Booking slot dulu sebelum scan QR'),
  ]) {
    testWidgets('a refused scan explains itself in ${locale.languageCode}', (
      tester,
    ) async {
      await pumpApp(
        tester,
        signedInAs: SampleSeeder.memberPhone,
        size: const Size(360, 780),
        locale: locale,
      );
      final actions = containerOf(tester).read(actionsProvider);
      final context = tester.element(find.byType(Scaffold).first);
      final ok = await runAction(
        context,
        () => actions.requestConnection(
          scannedCode: kSolarHubQr,
          applianceName: 'Oven',
          estKwh: 3,
        ),
      );
      await tester.pump();
      expect(ok, isFalse);
      expect(find.textContaining(expected), findsOneWidget);
    });
  }

  testWidgets('stored notifications and system messages follow the language', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signedInAs: SampleSeeder.adminPhone,
      size: const Size(360, 780),
      locale: english,
    );
    routerOf(tester).go(Paths.notifications);
    await tester.pumpAndSettle();
    expect(find.text('New member joined'), findsWidgets);
    expect(find.text('Anggota baru bergabung'), findsNothing);
  });

  testWidgets('a system message preview in the inbox is English', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signedInAs: SampleSeeder.memberPhone,
      size: const Size(360, 780),
      locale: english,
    );
    routerOf(tester).go(Paths.memberMessages);
    await tester.pumpAndSettle();
    expect(find.textContaining('Welcome to Koperasi Energi Melati'), findsOne);
    expect(find.textContaining('Selamat bergabung'), findsNothing);
  });

  for (final path in [
    Paths.memberHome,
    Paths.memberSolar,
    Paths.memberMessages,
    Paths.memberProfile,
    Paths.score,
    Paths.creditReport,
    Paths.loanApply,
    Paths.loans,
    Paths.installments,
    Paths.arisan,
    Paths.quota,
    Paths.energyAnalysis,
    Paths.energy,
    Paths.booking,
    Paths.bookings,
    Paths.appliances,
    Paths.applianceEdit,
    Paths.roof,
    Paths.hubConnect,
    Paths.quotaNew,
    Paths.notifications,
    Paths.changePin,
    Paths.language,
    Paths.profileEdit,
    Paths.about,
  ]) {
    testWidgets('member $path reads as English', (tester) async {
      await pumpApp(
        tester,
        signedInAs: SampleSeeder.memberPhone,
        size: const Size(360, 780),
        locale: english,
      );
      routerOf(tester).go(path);
      await tester.pumpAndSettle();
      expect(_offenders(tester), isEmpty);
    });
  }

  for (final path in [Paths.installments, Paths.loans, Paths.memberHome]) {
    testWidgets('borrower $path reads as English', (tester) async {
      await pumpApp(
        tester,
        signedInAs: '081200000005',
        size: const Size(360, 780),
        locale: english,
      );
      routerOf(tester).go(path);
      await tester.pumpAndSettle();
      expect(_offenders(tester), isEmpty);
    });
  }

  for (final path in [
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
  ]) {
    testWidgets('admin $path reads as English', (tester) async {
      await pumpApp(
        tester,
        signedInAs: SampleSeeder.adminPhone,
        size: const Size(360, 780),
        locale: english,
      );
      routerOf(tester).go(path);
      await tester.pumpAndSettle();
      expect(_offenders(tester), isEmpty);
    });
  }

  // The other direction: the default language must not leak English either.
  for (final path in [
    Paths.memberHome,
    Paths.memberSolar,
    Paths.memberMessages,
    Paths.memberProfile,
    Paths.score,
    Paths.creditReport,
    Paths.loanApply,
    Paths.loans,
    Paths.installments,
    Paths.arisan,
    Paths.quota,
    Paths.energyAnalysis,
    Paths.energy,
    Paths.booking,
    Paths.bookings,
    Paths.appliances,
    Paths.applianceEdit,
    Paths.roof,
    Paths.quotaNew,
    Paths.notifications,
    Paths.profileEdit,
    Paths.changePin,
    Paths.language,
    Paths.about,
  ]) {
    testWidgets('member $path reads as Indonesian', (tester) async {
      await pumpApp(
        tester,
        signedInAs: SampleSeeder.memberPhone,
        size: const Size(360, 780),
      );
      routerOf(tester).go(path);
      await tester.pumpAndSettle();
      expect(_offenders(tester, _english), isEmpty);
    });
  }

  for (final path in [Paths.installments, Paths.loans, Paths.memberHome]) {
    testWidgets('borrower $path reads as Indonesian', (tester) async {
      await pumpApp(
        tester,
        signedInAs: '081200000005',
        size: const Size(360, 780),
      );
      routerOf(tester).go(path);
      await tester.pumpAndSettle();
      expect(_offenders(tester, _english), isEmpty);
    });
  }

  for (final path in [
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
  ]) {
    testWidgets('admin $path reads as Indonesian', (tester) async {
      await pumpApp(
        tester,
        signedInAs: SampleSeeder.adminPhone,
        size: const Size(360, 780),
      );
      routerOf(tester).go(path);
      await tester.pumpAndSettle();
      expect(_offenders(tester, _english), isEmpty);
    });
  }
}
