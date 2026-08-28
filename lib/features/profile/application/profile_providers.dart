import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../../core/demo/demo_scenario.dart';
import '../data/demo_profile_repository.dart';
import '../domain/profile_repository.dart';

/// Picks the repository implementation. MVP: always the demo one
/// (docs/ARCHITECTURE.md §4). Future: switch on `AppConfig.isDemo`.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return DemoProfileRepository(ref.watch(demoRepositoryProvider));
});

final profileUserProvider = Provider<DemoUser>((ref) {
  return ref.watch(profileRepositoryProvider).currentUser();
});
