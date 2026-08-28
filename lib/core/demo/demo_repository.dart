import '../../features/arisan/domain/arisan_rules.dart';
import 'demo_scenario.dart';
import 'demo_session.dart';

/// REPOSITORY layer (docs/ARCHITECTURE.md §4).
///
/// A thin, synchronous read/write facade over [DemoSessionState]. Reads come
/// straight from the current immutable snapshot; mutations are delegated to
/// [DemoSessionNotifier], which validates them and publishes a new snapshot so
/// Riverpod observers rebuild.
abstract interface class DemoRepository {
  DemoScenario get current;

  // Solar bookings
  List<DemoSolarBooking> get bookings;
  void addBooking(DemoSolarBooking booking);

  // Arisan ledger (append-only)
  void appendLedgerEntry(DemoLedgerEntry entry);

  // Quota mutations — return an explicit outcome (docs/DATA_MODEL.md §3.10).
  ShareQuotaOutcome shareQuota({
    required double kwh,
    required String slotLabel,
    String? note,
  });
  TakeOfferOutcome takeOffer(String offerId, {String? note});

  // Quota offers (session-published first, then seeded)
  List<DemoQuotaOffer> get allOffers;

  /// Restore to the canonical seed state.
  void reset();
}

/// The [DemoRepository] backed by the observable demo session.
///
/// This facade is intentionally *not* reactive — it holds only the (stable)
/// notifier. Widgets and feature providers that must rebuild on a mutation
/// should `ref.watch(demoSessionProvider)` and select their slice; this facade
/// exists for imperative mutation calls and for the profile repository.
class SessionDemoRepository implements DemoRepository {
  SessionDemoRepository(this._notifier);

  final DemoSessionNotifier _notifier;

  @override
  DemoScenario get current => _notifier.snapshot.scenario;

  @override
  List<DemoSolarBooking> get bookings =>
      List.unmodifiable(_notifier.snapshot.bookings);

  @override
  void addBooking(DemoSolarBooking booking) => _notifier.addBooking(booking);

  @override
  void appendLedgerEntry(DemoLedgerEntry entry) =>
      _notifier.appendLedgerEntry(entry);

  @override
  List<DemoQuotaOffer> get allOffers => _notifier.snapshot.allOffers;

  @override
  ShareQuotaOutcome shareQuota({
    required double kwh,
    required String slotLabel,
    String? note,
  }) => _notifier.shareQuota(kwh: kwh, slotLabel: slotLabel, note: note);

  @override
  TakeOfferOutcome takeOffer(String offerId, {String? note}) =>
      _notifier.takeOffer(offerId, note: note);

  @override
  void reset() => _notifier.reset();
}
