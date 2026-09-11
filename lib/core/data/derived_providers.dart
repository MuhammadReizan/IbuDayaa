/// Read-only views over [AppData]. Screens watch these, never the raw document,
/// so a change to how something is computed stays in one place.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/credit_score/application/credit_score_provider.dart';
import '../../features/credit_score/domain/credit_signals.dart';
import 'app_data_controller.dart';
import 'insights.dart';
import 'models.dart';

/// The latest bill's analysis, or null when no bill has been recorded.
final energyInsightProvider = Provider<EnergyInsight?>(
  (ref) => buildEnergyInsight(ref.watch(dataProvider)),
);

final impactProvider = Provider<ImpactMetrics>(
  (ref) => buildImpact(ref.watch(dataProvider)),
);

final observationsProvider = Provider<List<PowerObservation>>(
  (ref) => buildObservations(ref.watch(dataProvider)),
);

/// How much history the score stands on.
final creditReadinessProvider = Provider<CreditReadiness>(
  (ref) => buildReadiness(ref.watch(dataProvider)),
);

/// The score, or null while there is not enough history to compute one
/// honestly. Screens must handle the null case.
final creditScoreOrNullProvider = Provider((ref) {
  final data = ref.watch(dataProvider);
  final readiness = ref.watch(creditReadinessProvider);
  if (!readiness.isReady) return null;
  return ref
      .watch(creditScoringEngineProvider)
      .compute(buildCreditSignals(data));
});

// -- Bills / appliances -----------------------------------------------------

final billsProvider = Provider<List<Bill>>((ref) {
  final bills = [...ref.watch(dataProvider).bills]
    ..sort((a, b) => b.periodMonth.compareTo(a.periodMonth));
  return List.unmodifiable(bills);
});

final appliancesProvider = Provider<List<Appliance>>(
  (ref) => ref.watch(dataProvider).appliances,
);

// -- Solar hub --------------------------------------------------------------

final sessionsProvider = Provider<List<SolarSession>>((ref) {
  final s = [...ref.watch(dataProvider).sessions]
    ..sort((a, b) => b.date.compareTo(a.date));
  return List.unmodifiable(s);
});

// -- Arisan -----------------------------------------------------------------

final arisanProvider = Provider<ArisanGroup?>(
  (ref) => ref.watch(dataProvider).arisan,
);

final ledgerProvider = Provider<List<LedgerEntry>>((ref) {
  final l = [...ref.watch(dataProvider).ledger]
    ..sort((a, b) => b.at.compareTo(a.at));
  return List.unmodifiable(l);
});

final offersProvider = Provider<List<QuotaOffer>>((ref) {
  final o = [...ref.watch(dataProvider).offers]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return List.unmodifiable(o);
});

/// Energy the user has published and not yet had taken.
final openOfferKwhProvider = Provider<double>(
  (ref) => ref
      .watch(offersProvider)
      .where((o) => o.status == 'open')
      .fold<double>(0, (s, o) => s + o.amountKwh),
);

// -- Financing --------------------------------------------------------------

final savedCalculationsProvider = Provider<List<SavedCalculation>>((ref) {
  final c = [...ref.watch(dataProvider).calculations]
    ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  return List.unmodifiable(c);
});

// -- Notifications ----------------------------------------------------------

/// Observations the user has not dismissed yet, newest concerns first.
final unreadObservationsProvider = Provider<List<PowerObservation>>((ref) {
  final read = ref.watch(dataProvider).readNotificationIds;
  return ref
      .watch(observationsProvider)
      .where((o) => !read.contains(o.id))
      .toList();
});

final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(unreadObservationsProvider).length,
);

// ---------------------------------------------------------------------------

/// Every provider derived from [dataProvider].
///
/// Riverpod pauses a widget's subscriptions while its route is off-screen. A
/// provider that changed during that time is flushed when the widget resumes —
/// which happens *during* a build, and cascading that flush into dependent
/// providers trips a setState-during-build assertion. Holding a listener above
/// the Navigator keeps these flushed at all times, so a resuming screen never
/// finds stale work to do.
final _derived = <Provider<Object?>>[
  dataProvider,
  profileProvider,
  energyInsightProvider,
  impactProvider,
  observationsProvider,
  creditReadinessProvider,
  creditScoreOrNullProvider,
  billsProvider,
  appliancesProvider,
  sessionsProvider,
  arisanProvider,
  ledgerProvider,
  offersProvider,
  openOfferKwhProvider,
  savedCalculationsProvider,
  unreadObservationsProvider,
  unreadCountProvider,
];

/// Subscribes to every derived provider without rebuilding the caller.
/// Call once from the root widget, above the Navigator.
void keepDerivedProvidersWarm(WidgetRef ref) {
  for (final p in _derived) {
    ref.listen<Object?>(p, (_, _) {});
  }
}
