import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../../core/demo/demo_scenario.dart';

/// Exposes the energy insight simulation data.
final energyInsightProvider = Provider<DemoEnergyInsight?>((ref) {
  return ref.watch(currentScenarioProvider).energyInsight;
});
