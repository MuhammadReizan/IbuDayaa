import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/data/app_data_controller.dart';
import '../core/data/models.dart';
import '../core/design/components/state_views.dart';
import '../features/about/presentation/about_screen.dart';
import '../features/appliances/presentation/appliance_edit_screen.dart';
import '../features/appliances/presentation/appliances_screen.dart';
import '../features/arisan/presentation/arisan_create_screen.dart';
import '../features/arisan/presentation/arisan_screen.dart';
import '../features/arisan/presentation/quota_share_screen.dart';
import '../features/arisan/presentation/quota_trading_screen.dart';
import '../features/bills/presentation/bill_add_screen.dart';
import '../features/bills/presentation/bills_screen.dart';
import '../features/bills/presentation/energy_analysis_screen.dart';
import '../features/credit_score/presentation/credit_score_screen.dart';
import '../features/financing/presentation/financing_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/app_settings_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/solar_hub/presentation/roof_check_screen.dart';
import '../features/solar_hub/presentation/session_add_screen.dart';
import '../features/solar_hub/presentation/solar_hub_screen.dart';
import 'splash_screen.dart';

/// Stable route names + paths. Navigate with these constants, never string
/// literals scattered across widgets.
abstract final class AppRoute {
  static const String splashPath = '/';

  static const String onboarding = 'onboarding';
  static const String onboardingPath = '/onboarding';

  // Bottom-nav branches.
  static const String home = 'home';
  static const String homePath = '/home';
  static const String solar = 'solar';
  static const String solarPath = '/solar';
  static const String arisan = 'arisan';
  static const String arisanPath = '/arisan';
  static const String profile = 'profile';
  static const String profilePath = '/profile';

  // Bills.
  static const String bills = 'bills';
  static const String billsPath = '/bills';
  static const String billAdd = 'billAdd';
  static const String billAddPath = '/bills/add';
  static const String energyAnalysis = 'energyAnalysis';
  static const String energyAnalysisPath = '/energy-analysis';

  // Appliances.
  static const String appliances = 'appliances';
  static const String appliancesPath = '/appliances';
  static const String applianceEdit = 'applianceEdit';
  static const String applianceEditPath = '/appliances/edit';

  // Solar hub.
  static const String roofCheck = 'roofCheck';
  static const String roofCheckPath = '/roof-check';
  static const String sessionAdd = 'sessionAdd';
  static const String sessionAddPath = '/session/add';

  // Arisan.
  static const String arisanCreate = 'arisanCreate';
  static const String arisanCreatePath = '/arisan/create';
  static const String quotaTrading = 'quotaTrading';
  static const String quotaTradingPath = '/quota';
  static const String quotaShare = 'quotaShare';
  static const String quotaSharePath = '/quota/share';

  // Money.
  static const String creditScore = 'creditScore';
  static const String creditScorePath = '/credit-score';
  static const String financing = 'financing';
  static const String financingPath = '/financing';

  // Support.
  static const String notifications = 'notifications';
  static const String notificationsPath = '/notifications';
  static const String about = 'about';
  static const String aboutPath = '/about';
  static const String appSettings = 'appSettings';
  static const String appSettingsPath = '/settings';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoute.splashPath,
    // Nothing but the splash and onboarding is reachable until a profile
    // exists, so no screen ever has to cope with a null user.
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == AppRoute.splashPath) return null;

      final data = ref.read(appDataProvider).value;
      if (data == null) return null; // still loading; splash handles it

      final onboarding = loc == AppRoute.onboardingPath;
      if (!data.isOnboarded && !onboarding) return AppRoute.onboardingPath;
      if (data.isOnboarded && onboarding) return AppRoute.homePath;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.splashPath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.onboardingPath,
        name: AppRoute.onboarding,
        builder: (context, state) => const OnboardingScreen(),
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
                path: AppRoute.arisanPath,
                name: AppRoute.arisan,
                builder: (context, state) => const ArisanScreen(),
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

      // Pushed over the shell.
      GoRoute(
        path: AppRoute.billsPath,
        name: AppRoute.bills,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BillsScreen(),
      ),
      GoRoute(
        path: AppRoute.billAddPath,
        name: AppRoute.billAdd,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            BillAddScreen(existing: state.extra as Bill?),
      ),
      GoRoute(
        path: AppRoute.energyAnalysisPath,
        name: AppRoute.energyAnalysis,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EnergyAnalysisScreen(),
      ),

      GoRoute(
        path: AppRoute.appliancesPath,
        name: AppRoute.appliances,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AppliancesScreen(),
      ),
      GoRoute(
        path: AppRoute.applianceEditPath,
        name: AppRoute.applianceEdit,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ApplianceEditScreen(existing: state.extra as Appliance?),
      ),

      GoRoute(
        path: AppRoute.roofCheckPath,
        name: AppRoute.roofCheck,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RoofCheckScreen(),
      ),
      GoRoute(
        path: AppRoute.sessionAddPath,
        name: AppRoute.sessionAdd,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SessionAddScreen(),
      ),

      GoRoute(
        path: AppRoute.arisanCreatePath,
        name: AppRoute.arisanCreate,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ArisanCreateScreen(),
      ),
      GoRoute(
        path: AppRoute.quotaTradingPath,
        name: AppRoute.quotaTrading,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuotaTradingScreen(),
      ),
      GoRoute(
        path: AppRoute.quotaSharePath,
        name: AppRoute.quotaShare,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuotaShareScreen(),
      ),

      GoRoute(
        path: AppRoute.creditScorePath,
        name: AppRoute.creditScore,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreditScoreScreen(),
      ),
      GoRoute(
        path: AppRoute.financingPath,
        name: AppRoute.financing,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FinancingScreen(),
      ),

      GoRoute(
        path: AppRoute.notificationsPath,
        name: AppRoute.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoute.aboutPath,
        name: AppRoute.about,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoute.appSettingsPath,
        name: AppRoute.appSettings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AppSettingsScreen(),
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
