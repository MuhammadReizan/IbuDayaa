import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/arisan/domain/arisan_rules.dart';
import 'demo_providers.dart';
import 'demo_scenario.dart';

/// Observable, immutable snapshot of the demo session (docs/ARCHITECTURE.md §5).
///
///   seed DemoScenario
///     → [DemoSessionState] / [DemoSessionNotifier]
///     → domain mutation (validated)
///     → providers
///     → UI
///
/// Every mutation replaces [state] with a new value so Riverpod observers
/// rebuild. Nothing here is mutated in place.
@immutable
class DemoSessionState {
  const DemoSessionState({
    required this.scenario,
    required this.bookings,
    required this.sessionOffers,
    required this.quotaRequests,
  });

  /// The current scenario. Seeded fields that change in-session (quota, arisan
  /// ledger, seeded offer status) are carried here via `copyWith`.
  final DemoScenario scenario;

  /// Solar Hub bookings created this session (append-only).
  final List<DemoSolarBooking> bookings;

  /// Quota offers the current user published this session (append-only).
  final List<DemoQuotaOffer> sessionOffers;

  /// Quota requests the current user made this session (append-only).
  final List<DemoQuotaRequest> quotaRequests;

  /// Session-published offers followed by seeded offers.
  List<DemoQuotaOffer> get allOffers =>
      List.unmodifiable([...sessionOffers, ...scenario.offers]);

  factory DemoSessionState.seed(DemoScenario scenario) => DemoSessionState(
    scenario: scenario,
    bookings: const [],
    sessionOffers: const [],
    quotaRequests: const [],
  );

  DemoSessionState copyWith({
    DemoScenario? scenario,
    List<DemoSolarBooking>? bookings,
    List<DemoQuotaOffer>? sessionOffers,
    List<DemoQuotaRequest>? quotaRequests,
  }) => DemoSessionState(
    scenario: scenario ?? this.scenario,
    bookings: bookings ?? this.bookings,
    sessionOffers: sessionOffers ?? this.sessionOffers,
    quotaRequests: quotaRequests ?? this.quotaRequests,
  );
}

/// Owns [DemoSessionState] and all in-session mutations. Mutation methods
/// validate against [arisan_rules] and return an explicit outcome instead of
/// silently succeeding or no-op-ing.
class DemoSessionNotifier extends Notifier<DemoSessionState> {
  /// The canonical seed captured at build time — [reset] restores exactly this.
  late DemoScenario _seed;

  @override
  DemoSessionState build() {
    _seed = ref.watch(demoScenarioProvider).requireValue;
    return DemoSessionState.seed(_seed);
  }

  /// Public read access to the current snapshot for the repository facade.
  /// Widgets/providers should `ref.watch(demoSessionProvider)` instead.
  DemoSessionState get snapshot => state;

  // -------------------------------------------------------------------------
  // Solar bookings
  // -------------------------------------------------------------------------

  void addBooking(DemoSolarBooking booking) {
    state = state.copyWith(bookings: [...state.bookings, booking]);
  }

  // -------------------------------------------------------------------------
  // Arisan ledger (append-only, newest first)
  // -------------------------------------------------------------------------

  void appendLedgerEntry(DemoLedgerEntry entry) {
    state = state.copyWith(scenario: _withLedger(state.scenario, entry));
  }

  DemoScenario _withLedger(DemoScenario scenario, DemoLedgerEntry entry) {
    return scenario.copyWith(
      arisan: scenario.arisan.copyWith(
        ledger: [entry, ...scenario.arisan.ledger],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Quota mutations (docs/DATA_MODEL.md §3.10)
  // -------------------------------------------------------------------------

  /// Publish [kwh] of the current user's quota as an open offer. Rejects a
  /// non-positive amount or one greater than the available quota — an invalid
  /// amount is never clamped and published as a smaller/larger offer.
  ShareQuotaOutcome shareQuota({
    required double kwh,
    required String slotLabel,
    String? note,
  }) {
    final quota = state.scenario.quota;
    final error = validateShareQuota(
      kwh: kwh,
      availableKwh: quota.availableKwh,
    );
    if (error != null) return ShareQuotaOutcome.failure(error);

    final user = state.scenario.user;
    final now = DateTime.now();
    final String? cleanNote = (note != null && note.trim().isEmpty)
        ? null
        : note?.trim();

    final offer = DemoQuotaOffer(
      id: 'off-${now.microsecondsSinceEpoch}',
      ownerMemberId: user.id,
      ownerName: user.displayName,
      amountKwh: kwh,
      slotLabel: slotLabel,
      note: cleanNote,
      status: 'open',
      createdAt: now,
    );

    final ledgerEntry = DemoLedgerEntry(
      id: 'LED-s-${now.microsecondsSinceEpoch}',
      type: 'quotaShared',
      memberId: user.id,
      memberName: user.displayName,
      amountKwh: kwh,
      timestamp: now,
      status: 'pending',
      note: cleanNote,
    );

    final nextScenario = _withLedger(
      state.scenario.copyWith(
        quota: quota.copyWith(availableKwh: quota.availableKwh - kwh),
      ),
      ledgerEntry,
    );

    state = state.copyWith(
      scenario: nextScenario,
      sessionOffers: [...state.sessionOffers, offer],
    );
    return ShareQuotaOutcome.success(offer);
  }

  /// Take an open offer that is not the current user's own. Rejects an unknown,
  /// non-open, already-taken or own offer, a take when no quota is needed, and
  /// a repeat take of the same offer (double-tap guard).
  TakeOfferOutcome takeOffer(String offerId, {String? note}) {
    final all = [...state.sessionOffers, ...state.scenario.offers];
    final int idx = all.indexWhere((o) => o.id == offerId);
    final DemoQuotaOffer? offer = idx >= 0 ? all[idx] : null;

    final error = validateTakeOffer(
      offer: offer,
      currentUserId: state.scenario.user.id,
      neededKwh: state.scenario.quota.neededKwh,
      alreadyRequested: state.quotaRequests.any((r) => r.offerId == offerId),
    );
    if (error != null) return TakeOfferOutcome.failure(error);

    // Mark the offer taken in whichever list holds it.
    final DemoQuotaOffer taken = offer!.copyWith(status: 'taken');
    List<DemoQuotaOffer> sessionOffers = state.sessionOffers;
    List<DemoQuotaOffer> seededOffers = state.scenario.offers;

    final int sIdx = sessionOffers.indexWhere((o) => o.id == offerId);
    if (sIdx >= 0) {
      sessionOffers = [...sessionOffers]..[sIdx] = taken;
    } else {
      final int gIdx = seededOffers.indexWhere((o) => o.id == offerId);
      seededOffers = [...seededOffers]..[gIdx] = taken;
    }

    final user = state.scenario.user;
    final now = DateTime.now();
    final String? cleanNote = (note != null && note.trim().isEmpty)
        ? null
        : note?.trim();

    final double newNeeded =
        (state.scenario.quota.neededKwh - offer.amountKwh) <= 0
        ? 0.0
        : state.scenario.quota.neededKwh - offer.amountKwh;

    final ledgerEntry = DemoLedgerEntry(
      id: 'LED-r-${now.microsecondsSinceEpoch}',
      type: 'quotaReceived',
      memberId: user.id,
      memberName: user.displayName,
      amountKwh: offer.amountKwh,
      timestamp: now,
      status: 'pending',
      note: cleanNote,
    );

    final request = DemoQuotaRequest(
      id: 'req-${now.microsecondsSinceEpoch}',
      offerId: offerId,
      amountKwh: offer.amountKwh,
      note: cleanNote,
      createdAt: now,
    );

    final nextScenario = _withLedger(
      state.scenario.copyWith(
        offers: seededOffers,
        quota: state.scenario.quota.copyWith(neededKwh: newNeeded),
      ),
      ledgerEntry,
    );

    state = state.copyWith(
      scenario: nextScenario,
      sessionOffers: sessionOffers,
      quotaRequests: [...state.quotaRequests, request],
    );
    return TakeOfferOutcome.success(taken);
  }

  // -------------------------------------------------------------------------
  // Reset
  // -------------------------------------------------------------------------

  /// Restore the exact canonical seed captured at build time.
  void reset() => state = DemoSessionState.seed(_seed);
}
