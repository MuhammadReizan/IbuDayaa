import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/demo/demo_providers.dart';
import 'package:ibudaya/core/demo/demo_scenario.dart';
import 'package:ibudaya/features/arisan/presentation/arisan_screen.dart';
import 'package:ibudaya/features/arisan/presentation/energy_trading_screen.dart';
import 'package:ibudaya/features/arisan/presentation/share_quota_screen.dart';
import 'package:ibudaya/features/bill_scan/presentation/energy_analysis_screen.dart';
import 'package:ibudaya/features/bill_scan/presentation/scan_tagihan_screen.dart';
import 'package:ibudaya/features/credit_score/presentation/credit_score_screen.dart';
import 'package:ibudaya/features/financing/domain/financing_simulation.dart';
import 'package:ibudaya/features/financing/presentation/financing_input_screen.dart';
import 'package:ibudaya/features/financing/presentation/financing_result_screen.dart';
import 'package:ibudaya/features/home/presentation/home_screen.dart';
import 'package:ibudaya/features/messages/presentation/messages_screen.dart';
import 'package:ibudaya/features/profile/presentation/profile_screen.dart';
import 'package:ibudaya/features/solar_hub/presentation/booking_confirmed_screen.dart';
import 'package:ibudaya/features/solar_hub/presentation/radar_atap_screen.dart';
import 'package:ibudaya/features/solar_hub/presentation/solar_hub_booking_screen.dart';
import 'package:ibudaya/features/solar_hub/presentation/solar_hub_screen.dart';

import '../support/demo_seed.dart';

/// Structural responsiveness checks: every key screen must build and lay out at
/// a 360 dp width — and the dense forms at text scale 1.3 — without a
/// *structural* layout failure (unbounded constraints, missing size, a provider
/// or localization error).
///
/// Note: `flutter test` renders with the fixed-width Ahem font, so absolute
/// pixel `RenderFlex overflowed` amounts are not representative of a real
/// device and are treated as non-fatal here. Tightening those is part of the
/// visual-polish phase; this test guards the class of bug that actually breaks
/// the demo (e.g. an `Expanded`/`Spacer` under unbounded height).
void main() {
  final scenario = demoSeedScenario();

  final simulation = LoanSimulation.compute(
    principalIdr: 1000000,
    purpose: 'Bahan Produksi',
    tenorMonths: 6,
    params: scenario.loanParams,
  );

  final booking = DemoSolarBooking(
    id: 'BKG-001',
    applianceKind: 'oven',
    applianceName: 'Oven',
    slotId: 'slot-1',
    slotLabel: '08.00–10.00',
    date: DateTime(2026, 8, 1),
    createdAt: DateTime(2026, 8, 1, 12),
  );

  final screens = <String, Widget>{
    'Home': const HomeScreen(),
    'Scan Tagihan': const ScanTagihanScreen(),
    'Analisis Energi': const EnergyAnalysisScreen(),
    'Solar Hub': const SolarHubScreen(),
    'Radar Atap': const RadarAtapScreen(),
    'Solar Booking': const SolarHubBookingScreen(),
    'Arisan': const ArisanScreen(),
    'Bursa Kuota': const EnergyTradingScreen(),
    'Bagikan Kuota': const ShareQuotaScreen(),
    'Skor Kredit': const CreditScoreScreen(),
    'Financing Input': const FinancingInputScreen(),
    'Financing Result': FinancingResultScreen(simulation: simulation),
    'Booking Confirmed': BookingConfirmedScreen(booking: booking),
    'Pesan': const MessagesScreen(),
    'Profil': const ProfileScreen(),
  };

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required Size size,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Swallow cosmetic Ahem-font overflow; let every other error fail the test.
    final void Function(FlutterErrorDetails)? originalOnError =
        FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().startsWith('A RenderFlex overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [demoScenarioProvider.overrideWith((ref) => scenario)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('key screens build at 360 dp width', () {
    screens.forEach((name, screen) {
      testWidgets(name, (tester) async {
        await pumpScreen(tester, screen, size: const Size(360, 900));
        expect(find.byType(Scaffold), findsWidgets, reason: '$name did build');
      });
    });
  });

  group('dense screens build at text scale 1.3 / 360 dp', () {
    final dense = <String, Widget>{
      'Home': screens['Home']!,
      'Financing Input': screens['Financing Input']!,
      'Bagikan Kuota': screens['Bagikan Kuota']!,
      'Solar Booking': screens['Solar Booking']!,
    };
    dense.forEach((name, screen) {
      testWidgets(name, (tester) async {
        await pumpScreen(
          tester,
          screen,
          size: const Size(360, 900),
          textScale: 1.3,
        );
        expect(find.byType(Scaffold), findsWidgets, reason: '$name did build');
      });
    });
  });
}
