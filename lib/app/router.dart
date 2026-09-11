import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/models.dart';
import '../core/paths.dart';
import '../core/state/app_state.dart';
import '../features/admin/admin_home_screen.dart';
import '../features/admin/admin_loans_screen.dart';
import '../features/admin/admin_members_screen.dart';
import '../features/admin/admin_more_screen.dart';
import '../features/admin/announce_screen.dart';
import '../features/admin/arisan_admin_screen.dart';
import '../features/admin/coop_settings_screen.dart';
import '../features/admin/hub_settings_screen.dart';
import '../features/admin/member_detail_screen.dart';
import '../features/admin/payments_review_screen.dart';
import '../features/arisan/arisan_screen.dart';
import '../features/arisan/quota_market_screen.dart';
import '../features/arisan/quota_post_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_admin_screen.dart';
import '../features/auth/register_choice_screen.dart';
import '../features/auth/register_member_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/credit_score/presentation/score_screen.dart';
import '../features/energy/appliance_form_screen.dart';
import '../features/energy/appliances_screen.dart';
import '../features/energy/energy_analysis_screen.dart';
import '../features/energy/energy_form_screen.dart';
import '../features/energy/energy_records_screen.dart';
import '../features/energy/scan_bill_screen.dart';
import '../features/home/member_home_screen.dart';
import '../features/loans/loan_apply_screen.dart';
import '../features/loans/loan_detail_screen.dart';
import '../features/loans/loans_screen.dart';
import '../features/messages/messages_screen.dart';
import '../features/messages/notifications_screen.dart';
import '../features/messages/thread_screen.dart';
import '../features/profile/about_screen.dart';
import '../features/profile/change_pin_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shell/shells.dart';
import '../features/solar/booking_screen.dart';
import '../features/solar/bookings_screen.dart';
import '../features/solar/roof_scan_screen.dart';
import '../features/solar/solar_hub_screen.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

const _authPaths = {
  Paths.welcome,
  Paths.login,
  Paths.register,
  Paths.registerMember,
  Paths.registerAdmin,
};

/// Paths both roles may open. Everything else under `/a/` is admin-only, and
/// everything outside it is member-only.
const _sharedPrefixes = [
  '/thread/',
  Paths.notifications,
  '/profile/',
  Paths.about,
];

String homeFor(Profile me) => me.isAdmin ? Paths.adminHome : Paths.memberHome;

/// Pure so it can be tested without a router.
String? guard(Profile? me, String location) {
  final isAuth = _authPaths.contains(location) || location == Paths.splash;
  if (me == null) {
    return isAuth && location != Paths.splash ? null : Paths.welcome;
  }
  if (isAuth) return homeFor(me);
  if (_sharedPrefixes.any(location.startsWith)) return null;
  final adminArea = location.startsWith('/a/');
  if (me.isAdmin && !adminArea) return Paths.adminHome;
  if (!me.isAdmin && adminArea) return Paths.memberHome;
  return null;
}

/// Rebuilt never; re-evaluates redirects when the signed-in account changes.
final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<String?>(ref.read(appStateProvider).me?.id);
  ref.listen(appStateProvider, (_, next) => session.value = next.me?.id);
  ref.onDispose(session.dispose);

  final me = ref.read(appStateProvider).me;
  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: me == null ? Paths.welcome : homeFor(me),
    refreshListenable: session,
    redirect: (context, state) =>
        guard(ref.read(appStateProvider).me, state.matchedLocation),
    routes: [
      GoRoute(path: Paths.splash, redirect: (_, _) => Paths.welcome),
      GoRoute(path: Paths.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Paths.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: Paths.register,
        builder: (_, _) => const RegisterChoiceScreen(),
      ),
      GoRoute(
        path: Paths.registerMember,
        builder: (_, s) =>
            RegisterMemberScreen(initialCode: s.uri.queryParameters['kode']),
      ),
      GoRoute(
        path: Paths.registerAdmin,
        builder: (_, _) => const RegisterAdminScreen(),
      ),

      // -- Member ------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MemberShell(shell: shell),
        branches: [
          _branch(Paths.memberHome, const MemberHomeScreen()),
          _branch(Paths.memberSolar, const SolarHubScreen()),
          _branch(Paths.memberMessages, const MessagesScreen()),
          _branch(Paths.memberProfile, const ProfileScreen()),
        ],
      ),
      _page(Paths.scan, (_) => const ScanBillScreen()),
      _page(Paths.energy, (_) => const EnergyRecordsScreen()),
      _page(
        Paths.energyAdd,
        (s) => EnergyFormScreen(draft: s.extra as EnergyDraft?),
      ),
      _page(Paths.energyAnalysis, (_) => const EnergyAnalysisScreen()),
      _page(Paths.appliances, (_) => const AppliancesScreen()),
      _page(
        Paths.applianceEdit,
        (s) => ApplianceFormScreen(existing: s.extra as Appliance?),
      ),
      _page(Paths.roof, (_) => const RoofScanScreen()),
      _page(
        Paths.booking,
        (s) => BookingScreen(applianceName: s.uri.queryParameters['alat']),
      ),
      _page(Paths.bookings, (_) => const BookingsScreen()),
      _page(Paths.arisan, (_) => const ArisanScreen()),
      _page(Paths.quota, (_) => const QuotaMarketScreen()),
      _page(
        Paths.quotaNew,
        (s) => QuotaPostScreen(
          kind: s.uri.queryParameters['jenis'] == 'butuh'
              ? QuotaKind.need
              : QuotaKind.share,
        ),
      ),
      _page(Paths.score, (_) => const ScoreScreen()),
      _page(Paths.loanApply, (_) => const LoanApplyScreen()),
      _page(
        Paths.loans,
        (_) => const LoansScreen(),
        routes: [
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootKey,
            builder: (_, s) =>
                LoanDetailScreen(loanId: s.pathParameters['id']!),
          ),
        ],
      ),

      // -- Shared ------------------------------------------------------------
      _page(
        '/thread/:id',
        (s) => ThreadScreen(threadId: s.pathParameters['id']!),
      ),
      _page(Paths.notifications, (_) => const NotificationsScreen()),
      _page(Paths.profileEdit, (_) => const EditProfileScreen()),
      _page(Paths.changePin, (_) => const ChangePinScreen()),
      _page(Paths.about, (_) => const AboutScreen()),

      // -- Admin -------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AdminShell(shell: shell),
        branches: [
          _branch(Paths.adminHome, const AdminHomeScreen()),
          _branch(
            Paths.adminLoans,
            const AdminLoansScreen(),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootKey,
                builder: (_, s) => LoanDetailScreen(
                  loanId: s.pathParameters['id']!,
                  adminView: true,
                ),
              ),
            ],
          ),
          _branch(
            Paths.adminMembers,
            const AdminMembersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootKey,
                builder: (_, s) =>
                    MemberDetailScreen(memberId: s.pathParameters['id']!),
              ),
            ],
          ),
          _branch(Paths.adminMore, const AdminMoreScreen()),
        ],
      ),
      _page(Paths.adminPayments, (_) => const PaymentsReviewScreen()),
      _page(
        Paths.adminArisan,
        (_) => const ArisanAdminScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const ArisanCreateScreen(),
          ),
        ],
      ),
      _page(Paths.adminHub, (_) => const HubSettingsScreen()),
      _page(Paths.adminAnnounce, (_) => const AnnounceScreen()),
      _page(Paths.adminSettings, (_) => const CoopSettingsScreen()),
      _page(Paths.adminMessages, (_) => const MessagesScreen(standalone: true)),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _branch(
  String path,
  Widget screen, {
  List<RouteBase> routes = const [],
}) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => screen, routes: routes)],
);

GoRoute _page(
  String path,
  Widget Function(GoRouterState) build, {
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  parentNavigatorKey: _rootKey,
  builder: (_, s) => build(s),
  routes: routes,
);
