import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../../core/demo/demo_scenario.dart';

final arisanGroupProvider = Provider<DemoArisanGroup>((ref) {
  return ref.watch(demoRepositoryProvider).current.arisan;
});

final energyQuotaProvider = Provider<DemoEnergyQuota>((ref) {
  return ref.watch(demoRepositoryProvider).current.quota;
});

final quotaOffersProvider = Provider<List<DemoQuotaOffer>>((ref) {
  return ref.watch(demoRepositoryProvider).allOffers;
});

final unreadMessagesCountProvider = Provider<int>((ref) {
  final threads = ref.watch(demoRepositoryProvider).current.threads;
  return threads.fold(0, (sum, t) => sum + t.unreadCount);
});
