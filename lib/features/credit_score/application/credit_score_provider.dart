/// Riverpod providers for the credit-scoring feature.
///
/// Layer: application (sits between domain and presentation).
/// docs/ARCHITECTURE.md §4 / AGENTS.MD §Architecture.
///
/// Data flow:
///   DemoScenario (JSON seed)
///     → DemoCreditInputs
///     → CreditScoreInputs
///     → DemoCreditScoringEngine.compute()
///     → CreditScore
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../data/demo_credit_scoring_engine.dart';
import '../domain/credit_scoring_engine.dart';

// ---------------------------------------------------------------------------
// Engine singleton
// ---------------------------------------------------------------------------

/// The scoring engine instance. Override in tests to inject a mock.
final creditScoringEngineProvider = Provider<CreditScoringEngine>(
  (ref) => const DemoCreditScoringEngine(),
  name: 'creditScoringEngineProvider',
);

// ---------------------------------------------------------------------------
// CreditScoreInputs — derived from the demo scenario (single source of truth)
// ---------------------------------------------------------------------------

/// Converts the seeded [DemoCreditInputs] into the engine's [CreditScoreInputs].
///
/// The demo scenario is the single source of truth for the raw signal values
/// (correction #3 — do not hardcode them here).
final creditScoreInputsProvider = Provider<CreditScoreInputs>((ref) {
  final scenario = ref.watch(demoRepositoryProvider).current;
  final seed = scenario.creditInputs;
  return CreditScoreInputs(
    energyUsageConsistency: seed.energyUsageConsistency,
    paymentHistory: seed.paymentHistory,
    businessActivity: seed.businessActivity,
    communityParticipation: seed.communityParticipation,
  );
}, name: 'creditScoreInputsProvider');

// ---------------------------------------------------------------------------
// CreditScore — the computed result
// ---------------------------------------------------------------------------

/// The computed [CreditScore] for the active demo scenario.
///
/// Re-computes automatically when the scenario or the engine changes.
/// For Demo Mode the result is always the same deterministic value.
///
/// Ibu Clara canonical: score = 82, band = Baik Sekali.
final creditScoreProvider = Provider<CreditScore>((ref) {
  final engine = ref.watch(creditScoringEngineProvider);
  final inputs = ref.watch(creditScoreInputsProvider);
  return engine.compute(inputs);
}, name: 'creditScoreProvider');
