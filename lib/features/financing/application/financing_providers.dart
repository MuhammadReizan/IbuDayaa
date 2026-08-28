import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../../core/demo/demo_scenario.dart';
import '../../credit_score/application/credit_score_provider.dart';

final loanParamsProvider = Provider<DemoLoanParams>((ref) {
  return ref.watch(currentScenarioProvider).loanParams;
});

final borrowingCeilingProvider = Provider<int>((ref) {
  final params = ref.watch(loanParamsProvider);
  final score = ref.watch(creditScoreProvider);

  if (score.score < params.eligibleScoreThreshold) {
    return 0;
  }
  return params.maxDemoFinancingIdr;
});
