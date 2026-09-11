/// Riverpod wiring for the credit-scoring feature.
///
/// Layer: application (sits between domain and presentation).
///
/// Data flow:
///   AppData (the user's own records)
///     → buildCreditSignals()   — arithmetic over recorded behaviour
///     → RuleBasedCreditScoringEngine.compute()
///     → CreditScore
///
/// The engine is deliberately rule-based and transparent: the four categories
/// shown on screen *are* the whole explanation. It is IbuDaya's own internal
/// score, not a bank or bureau score, and the UI must never describe it as AI.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/rule_based_credit_scoring_engine.dart';
import '../domain/credit_scoring_engine.dart';

/// The scoring engine instance. Override in tests to inject a fake.
final creditScoringEngineProvider = Provider<CreditScoringEngine>(
  (ref) => const RuleBasedCreditScoringEngine(),
  name: 'creditScoringEngineProvider',
);
