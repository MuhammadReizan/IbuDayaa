import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'demo_data_source.dart';
import 'demo_repository.dart';
import 'demo_scenario.dart';
import 'demo_session.dart';

/// Wiring for Demo Mode (docs/ARCHITECTURE.md §5).
///
///   [demoDataSourceProvider]  → loads the seed JSON
///   [demoScenarioProvider]    → bootstrap gate (loading / error / data)
///   [demoSessionProvider]     → observable, immutable session state + mutations
///   [demoRepositoryProvider]  → synchronous read/write facade over the session
///
/// Feature providers watch [demoRepositoryProvider] (or [demoSessionProvider]
/// directly) and rebuild whenever a mutation publishes a new snapshot.

final demoDataSourceProvider = Provider<DemoDataSource>((ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return AssetDemoDataSource(config.demoScenarioAsset);
});

/// Loads the seed once. Invalidate this to reload from the asset; a normal
/// "Reset Demo" uses [resetDemo] instead, which is synchronous and exact.
final demoScenarioProvider = FutureProvider<DemoScenario>((ref) {
  return ref.watch(demoDataSourceProvider).load();
});

/// The observable session state. Seeded from [demoScenarioProvider]; every
/// mutation replaces the state with a new immutable value.
final demoSessionProvider =
    NotifierProvider<DemoSessionNotifier, DemoSessionState>(
      DemoSessionNotifier.new,
    );

/// Synchronous repository facade for imperative mutation calls. Stable — it
/// holds only the notifier. Consumers that must rebuild on a mutation watch
/// [demoSessionProvider] directly.
final demoRepositoryProvider = Provider<DemoRepository>((ref) {
  return SessionDemoRepository(ref.watch(demoSessionProvider.notifier));
});

/// The current scenario. A stable slice of [demoSessionProvider]: mutations
/// that only touch session lists (e.g. bookings) do not change this value, so
/// screens watching it are not rebuilt for unrelated changes.
final currentScenarioProvider = Provider<DemoScenario>((ref) {
  return ref.watch(demoSessionProvider).scenario;
});

/// Convenience selector for the demo persona (Ibu Clara).
final currentUserProvider = Provider<DemoUser>((ref) {
  return ref.watch(currentScenarioProvider).user;
});

/// Perform a Demo Mode reset from anywhere with a [Ref]/[WidgetRef]. Restores
/// the exact canonical seed captured when the session was built.
void resetDemo(WidgetRef ref) => ref.read(demoSessionProvider.notifier).reset();
