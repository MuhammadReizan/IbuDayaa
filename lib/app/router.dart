import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/components/state_views.dart';
import '../core/demo/demo_scenario.dart';
import '../features/bill_scan/presentation/energy_analysis_screen.dart';
import '../features/bill_scan/presentation/scan_tagihan_screen.dart';
import '../features/credit_score/presentation/credit_score_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/messages/presentation/messages_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/solar_hub/presentation/booking_confirmed_screen.dart';
import '../features/solar_hub/presentation/radar_atap_screen.dart';
import '../features/solar_hub/presentation/solar_hub_booking_screen.dart';
import '../features/solar_hub/presentation/solar_hub_screen.dart';
import '../features/arisan/presentation/arisan_screen.dart';
import '../features/arisan/presentation/energy_trading_screen.dart';
import '../features/arisan/presentation/offer_published_screen.dart';
import '../features/arisan/presentation/share_quota_screen.dart';
import '../features/financing/domain/financing_simulation.dart';
import '../features/financing/presentation/financing_input_screen.dart';
import '../features/financing/presentation/financing_result_screen.dart';
import 'splash_screen.dart';

/// Stable route names + paths (docs/ARCHITECTURE.md §7). Navigate with these
/// constants, never string literals scattered across widgets.
abstract final class AppRoute {
  static const String splashPath = '/';

  static const String home = 'home';
  static const String homePath = '/home';
  static const String solar = 'solar';
  static const String solarPath = '/solar';
  static const String messages = 'messages';
  static const String messagesPath = '/messages';
  static const String profile = 'profile';
  static const String profilePath = '/profile';

  // Pushed on top of the shell.
  static const String creditScore = 'creditScore';
  static const String creditScorePath = '/credit-score';

  static const String scanTagihan = 'scanTagihan';
  static const String scanTagihanPath = '/scan-tagihan';

  static const String energyAnalysis = 'energyAnalysis';
  static const String energyAnalysisPath = '/energy-analysis';

  static const String radarAtap = 'radarAtap';
  static const String radarAtapPath = '/radar-atap';

  static const String solarBooking = 'solarBooking';
  static const String solarBookingPath = '/solar-booking';

  static const String bookingConfirmed = 'bookingConfirmed';
  static const String bookingConfirmedPath = '/booking-confirmed';

  // Stub routes — destination screens not yet implemented.
  static const String arisan = 'arisan';
  static const String arisanPath = '/arisan';
  static const String pembiayaan = 'pembiayaan';
  static const String pembiayaanPath = '/pembiayaan';

  static const String financing = 'financing';
  static const String financingPath = '/financing';

  static const String financingResult = 'financingResult';
  static const String financingResultPath = '/financing-result';

  static const String energyTrading = 'energyTrading';
  static const String energyTradingPath = '/energy-trading';

  static const String shareQuota = 'shareQuota';
  static const String shareQuotaPath = '/share-quota';

  static const String offerPublished = 'offerPublished';
  static const String offerPublishedPath = '/offer-published';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.splashPath,
    routes: [
      GoRoute(
        path: AppRoute.splashPath,
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.homePath,
                name: AppRoute.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.solarPath,
                name: AppRoute.solar,
                builder: (context, state) => const SolarHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.messagesPath,
                name: AppRoute.messages,
                builder: (context, state) => const MessagesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.profilePath,
                name: AppRoute.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Pushed on top of the shell (no bottom-nav visible).
      GoRoute(
        path: AppRoute.creditScorePath,
        name: AppRoute.creditScore,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreditScoreScreen(),
      ),

      GoRoute(
        path: AppRoute.scanTagihanPath,
        name: AppRoute.scanTagihan,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScanTagihanScreen(),
      ),
      GoRoute(
        path: AppRoute.energyAnalysisPath,
        name: AppRoute.energyAnalysis,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EnergyAnalysisScreen(),
      ),
      GoRoute(
        path: AppRoute.radarAtapPath,
        name: AppRoute.radarAtap,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RadarAtapScreen(),
      ),
      GoRoute(
        path: AppRoute.solarBookingPath,
        name: AppRoute.solarBooking,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SolarHubBookingScreen(),
      ),
      GoRoute(
        path: AppRoute.bookingConfirmedPath,
        name: AppRoute.bookingConfirmed,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final booking = state.extra as DemoSolarBooking;
          return BookingConfirmedScreen(booking: booking);
        },
      ),

      GoRoute(
        path: AppRoute.arisanPath,
        name: AppRoute.arisan,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ArisanScreen(),
      ),
      GoRoute(
        path: AppRoute.energyTradingPath,
        name: AppRoute.energyTrading,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EnergyTradingScreen(),
      ),
      GoRoute(
        path: AppRoute.shareQuotaPath,
        name: AppRoute.shareQuota,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShareQuotaScreen(),
      ),
      GoRoute(
        path: AppRoute.offerPublishedPath,
        name: AppRoute.offerPublished,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OfferPublishedScreen(),
      ),
      GoRoute(
        path: AppRoute.financingPath,
        name: AppRoute.financing,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FinancingInputScreen(),
      ),
      GoRoute(
        path: AppRoute.financingResultPath,
        name: AppRoute.financingResult,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final simulation = state.extra as LoanSimulation;
          return FinancingResultScreen(simulation: simulation);
        },
      ),
      // Stubs for unimplemented destination features.
      GoRoute(
        path: AppRoute.pembiayaanPath,
        name: AppRoute.pembiayaan,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const _StubScreen(title: 'Simulasi Pembiayaan'),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: ErrorStateView(
          message: 'Halaman tidak ditemukan.',
          onRetry: () => context.go(AppRoute.homePath),
        ),
      ),
    ),
  );
});

// ---------------------------------------------------------------------------
// Minimal stub screen shown for unimplemented destination features.
// PROTOTYPE_DECISION — replaced when the feature slice lands.
// ---------------------------------------------------------------------------

class _StubScreen extends StatelessWidget {
  const _StubScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(title),
      ),
      body: SafeArea(
        child: EmptyState(
          icon: Icons.construction_outlined,
          title: title,
          message: 'Fitur ini akan hadir segera.',
          action: TextButton(
            onPressed: () => context.go(AppRoute.homePath),
            child: const Text('Kembali ke Beranda'),
          ),
        ),
      ),
    );
  }
}
