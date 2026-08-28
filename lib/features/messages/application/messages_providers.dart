import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../../core/demo/demo_scenario.dart';

final messageThreadsProvider = Provider<List<DemoMessageThread>>((ref) {
  return ref.watch(currentScenarioProvider).threads;
});
