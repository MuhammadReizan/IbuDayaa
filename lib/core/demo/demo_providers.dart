import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'demo_data_source.dart';
import 'demo_repository.dart';
import 'demo_scenario.dart';

/// Wiring for Demo Mode (docs/ARCHITECTURE.md §5).
///
///   UI → provider → [DemoRepository] → [DemoDataSource]
///
/// [demoScenarioProvider] is the bootstrap gate: the app shows a loading
/// screen while it resolves and a retryable error screen if it fails.

final demoDataSourceProvider = Provider<DemoDataSource>((ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return AssetDemoDataSource(config.demoScenarioAsset);
});

/// Loads the seed once. Invalidate this to perform a "Reset Demo".
final demoScenarioProvider = FutureProvider<DemoScenario>((ref) {
  return ref.watch(demoDataSourceProvider).load();
});

/// The synchronous repository used by feature-level providers. Only valid once
/// [demoScenarioProvider] has data; feature screens sit behind the bootstrap
/// gate so that is always true when they build.
final demoRepositoryProvider = Provider<DemoRepository>((ref) {
  final DemoScenario scenario = ref.watch(demoScenarioProvider).requireValue;
  return LocalDemoRepository(scenario);
});

/// Convenience selector for the demo persona (Ibu Clara).
final currentUserProvider = Provider<DemoUser>((ref) {
  return ref.watch(demoRepositoryProvider).current.user;
});

/// Perform a Demo Mode reset from anywhere with a [Ref]/[WidgetRef].
void resetDemo(WidgetRef ref) => ref.invalidate(demoScenarioProvider);
