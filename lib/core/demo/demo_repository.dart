import 'package:flutter/foundation.dart';

import 'demo_scenario.dart';

/// REPOSITORY layer (docs/ARCHITECTURE.md §4).
///
/// Holds the *current* in-memory demo scenario and all in-session mutations.
/// [reset] returns to the originally-loaded snapshot.
abstract interface class DemoRepository {
  DemoScenario get current;

  // Solar bookings
  List<DemoSolarBooking> get bookings;
  void addBooking(DemoSolarBooking booking);

  // Arisan ledger (append-only)
  void appendLedgerEntry(DemoLedgerEntry entry);

  // Quota mutations
  void shareQuota({
    required double kwh,
    required String slotLabel,
    String? note,
  });
  void takeOffer(String offerId, {String? note});

  // Quota offers
  List<DemoQuotaOffer> get allOffers;

  /// Restore to seed state.
  void reset();
}

class LocalDemoRepository implements DemoRepository {
  LocalDemoRepository(this._seed)
    : _current = _seed,
      _bookings = [],
      _quotaRequests = [],
      _sessionOffers = [];

  final DemoScenario _seed;
  DemoScenario _current;
  final List<DemoSolarBooking> _bookings;
  final List<DemoQuotaRequest> _quotaRequests;

  /// User-published offers created in this session.
  final List<DemoQuotaOffer> _sessionOffers;

  @override
  DemoScenario get current => _current;

  // ---------------------------------------------------------------------------
  // Solar bookings
  // ---------------------------------------------------------------------------

  @override
  List<DemoSolarBooking> get bookings => List.unmodifiable(_bookings);

  @override
  void addBooking(DemoSolarBooking booking) {
    _bookings.add(booking);
  }

  // ---------------------------------------------------------------------------
  // Arisan ledger (append-only)
  // ---------------------------------------------------------------------------

  @override
  void appendLedgerEntry(DemoLedgerEntry entry) {
    final updated = _current.arisan.copyWith(
      ledger: [entry, ..._current.arisan.ledger],
    );
    _current = _current.copyWith(arisan: updated);
  }

  // ---------------------------------------------------------------------------
  // Quota mutations (docs/DATA_MODEL.md §3.10)
  // ---------------------------------------------------------------------------

  @override
  List<DemoQuotaOffer> get allOffers =>
      List.unmodifiable([..._sessionOffers, ..._current.offers]);

  @override
  void shareQuota({
    required double kwh,
    required String slotLabel,
    String? note,
  }) {
    assert(kwh > 0, 'kwh must be positive');
    final newAvailable = (_current.quota.availableKwh - kwh).clamp(
      0.0,
      double.infinity,
    );
    final newQuota = _current.quota.copyWith(availableKwh: newAvailable);

    final offer = DemoQuotaOffer(
      id: 'off-${DateTime.now().millisecondsSinceEpoch}',
      ownerMemberId: _current.user.id,
      ownerName: _current.user.displayName,
      amountKwh: kwh,
      slotLabel: slotLabel,
      note: note,
      status: 'open',
      createdAt: DateTime.now(),
    );
    _sessionOffers.add(offer);

    final ledgerEntry = DemoLedgerEntry(
      id: 'LED-${DateTime.now().millisecondsSinceEpoch}',
      type: 'quotaShared',
      memberId: _current.user.id,
      memberName: _current.user.displayName,
      amountKwh: kwh,
      timestamp: DateTime.now(),
      status: 'pending',
      note: note,
    );

    _current = _current.copyWith(quota: newQuota);
    appendLedgerEntry(ledgerEntry);
  }

  @override
  void takeOffer(String offerId, {String? note}) {
    // Find offer in seeded + session offers.
    final seededIdx = _current.offers.indexWhere((o) => o.id == offerId);
    final sessionIdx = _sessionOffers.indexWhere((o) => o.id == offerId);

    DemoQuotaOffer? offer;
    if (seededIdx >= 0) {
      offer = _current.offers[seededIdx];
      final updatedOffers = List<DemoQuotaOffer>.from(_current.offers);
      updatedOffers[seededIdx] = offer.copyWith(status: 'taken');
      _current = _current.copyWith(offers: updatedOffers);
    } else if (sessionIdx >= 0) {
      offer = _sessionOffers[sessionIdx];
      _sessionOffers[sessionIdx] = offer.copyWith(status: 'taken');
    }

    if (offer == null) return;

    // Reduce neededKwh.
    final newNeeded = (_current.quota.neededKwh - offer.amountKwh).clamp(
      0.0,
      double.infinity,
    );
    _current = _current.copyWith(
      quota: _current.quota.copyWith(neededKwh: newNeeded),
    );

    _quotaRequests.add(
      DemoQuotaRequest(
        id: 'req-${DateTime.now().millisecondsSinceEpoch}',
        offerId: offerId,
        amountKwh: offer.amountKwh,
        note: note,
        createdAt: DateTime.now(),
      ),
    );

    appendLedgerEntry(
      DemoLedgerEntry(
        id: 'LED-${DateTime.now().millisecondsSinceEpoch + 1}',
        type: 'quotaReceived',
        memberId: _current.user.id,
        memberName: _current.user.displayName,
        amountKwh: offer.amountKwh,
        timestamp: DateTime.now(),
        status: 'pending',
        note: note,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  @override
  void reset() {
    _current = _seed;
    _bookings.clear();
    _quotaRequests.clear();
    _sessionOffers.clear();
  }

  /// Internal hook for future feature slices to swap in a mutated scenario.
  @protected
  @visibleForTesting
  void replaceCurrent(DemoScenario next) => _current = next;
}
