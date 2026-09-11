import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_data.dart';
import 'app_store.dart';
import 'models.dart';

/// The store implementation. Override in tests with a [MemoryAppStore].
final appStoreProvider = Provider<AppStore>((ref) => FileAppStore());

/// The user's records, loaded once and persisted on every change.
final appDataProvider = AsyncNotifierProvider<AppDataController, AppData>(
  AppDataController.new,
);

/// Convenience: the loaded document, or an empty one while loading.
final dataProvider = Provider<AppData>((ref) {
  return ref.watch(appDataProvider).value ?? AppData.empty;
});

/// The signed-in person. Screens behind onboarding can assume this is non-null.
final profileProvider = Provider<UserProfile?>(
  (ref) => ref.watch(dataProvider).profile,
);

String _id(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

/// Owns [AppData] and every mutation to it.
///
/// Each mutation builds the next immutable document, publishes it so the UI
/// rebuilds immediately, then writes it to disk. The write is awaited so a
/// caller can surface a failure, but the UI never waits on I/O to update.
class AppDataController extends AsyncNotifier<AppData> {
  AppStore get _store => ref.read(appStoreProvider);

  @override
  Future<AppData> build() => _store.load();

  Future<void> _commit(AppData next) async {
    state = AsyncData(next);
    await _store.save(next);
  }

  AppData get _now => state.value ?? AppData.empty;

  // -- Profile --------------------------------------------------------------

  Future<void> completeOnboarding(UserProfile profile) =>
      _commit(_now.copyWith(profile: profile));

  Future<void> updateProfile(UserProfile profile) =>
      _commit(_now.copyWith(profile: profile));

  // -- Bills ----------------------------------------------------------------

  Future<Bill> addBill({
    required DateTime periodMonth,
    required double kwh,
    required int totalIdr,
    String? photoPath,
  }) async {
    final bill = Bill(
      id: _id('bill'),
      periodMonth: DateTime(periodMonth.year, periodMonth.month),
      kwh: kwh,
      totalIdr: totalIdr,
      photoPath: photoPath,
      recordedAt: DateTime.now(),
    );
    // Newest first, and one bill per month — re-recording a month replaces it.
    final bills = [
      bill,
      ..._now.bills.where(
        (b) =>
            b.periodMonth.year != bill.periodMonth.year ||
            b.periodMonth.month != bill.periodMonth.month,
      ),
    ]..sort((a, b) => b.periodMonth.compareTo(a.periodMonth));
    await _commit(_now.copyWith(bills: bills));
    return bill;
  }

  Future<void> deleteBill(String id) => _commit(
    _now.copyWith(bills: _now.bills.where((b) => b.id != id).toList()),
  );

  // -- Appliances -----------------------------------------------------------

  Future<void> addAppliance({
    required String name,
    required double watts,
    required double hoursPerDay,
    required int daysPerWeek,
    String kind = 'other',
  }) => _commit(
    _now.copyWith(
      appliances: [
        ..._now.appliances,
        Appliance(
          id: _id('app'),
          name: name,
          watts: watts,
          hoursPerDay: hoursPerDay,
          daysPerWeek: daysPerWeek,
          kind: kind,
        ),
      ],
    ),
  );

  Future<void> updateAppliance(Appliance appliance) => _commit(
    _now.copyWith(
      appliances: [
        for (final a in _now.appliances)
          if (a.id == appliance.id) appliance else a,
      ],
    ),
  );

  Future<void> deleteAppliance(String id) => _commit(
    _now.copyWith(
      appliances: _now.appliances.where((a) => a.id != id).toList(),
    ),
  );

  // -- Solar Hub sessions ---------------------------------------------------

  Future<SolarSession> addSession({
    required String applianceName,
    required DateTime date,
    required String slotLabel,
    required double kwh,
  }) async {
    final session = SolarSession(
      id: _id('ses'),
      applianceName: applianceName,
      date: date,
      slotLabel: slotLabel,
      kwh: kwh,
      recordedAt: DateTime.now(),
    );
    await _commit(_now.copyWith(sessions: [session, ..._now.sessions]));
    return session;
  }

  Future<void> deleteSession(String id) => _commit(
    _now.copyWith(sessions: _now.sessions.where((s) => s.id != id).toList()),
  );

  // -- Arisan ---------------------------------------------------------------

  Future<void> createArisan({
    required String name,
    required int contributionIdr,
    required List<String> memberNames,
  }) {
    final me = _now.profile?.name ?? 'Saya';
    final members = <ArisanMember>[
      ArisanMember(id: _id('mbr'), name: me, isMe: true),
      for (final n in memberNames)
        if (n.trim().isNotEmpty) ArisanMember(id: _id('mbr'), name: n.trim()),
    ];
    return _commit(
      _now.copyWith(
        arisan: ArisanGroup(
          name: name,
          contributionIdr: contributionIdr,
          members: members,
          startedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> updateArisan(ArisanGroup group) =>
      _commit(_now.copyWith(arisan: group));

  Future<void> addArisanMember(String name) {
    final group = _now.arisan;
    if (group == null || name.trim().isEmpty) return Future.value();
    return _commit(
      _now.copyWith(
        arisan: group.copyWith(
          members: [
            ...group.members,
            ArisanMember(id: _id('mbr'), name: name.trim()),
          ],
        ),
      ),
    );
  }

  Future<void> removeArisanMember(String id) {
    final group = _now.arisan;
    if (group == null) return Future.value();
    return _commit(
      _now.copyWith(
        arisan: group.copyWith(
          members: group.members.where((m) => m.id != id || m.isMe).toList(),
        ),
      ),
    );
  }

  Future<void> deleteArisan() =>
      _commit(_now.copyWith(clearArisan: true, ledger: const []));

  /// Records money in (a member paid their dues) or out (a member's turn).
  Future<void> recordLedger({
    required String type,
    required ArisanMember member,
    int? amountIdr,
    double? amountKwh,
    String? note,
    DateTime? at,
  }) => _commit(
    _now.copyWith(
      ledger: [
        LedgerEntry(
          id: _id('led'),
          type: type,
          memberId: member.id,
          memberName: member.name,
          amountIdr: amountIdr,
          amountKwh: amountKwh,
          at: at ?? DateTime.now(),
          note: (note == null || note.trim().isEmpty) ? null : note.trim(),
        ),
        ..._now.ledger,
      ],
    ),
  );

  Future<void> deleteLedgerEntry(String id) => _commit(
    _now.copyWith(ledger: _now.ledger.where((e) => e.id != id).toList()),
  );

  // -- Quota sharing --------------------------------------------------------

  Future<QuotaOffer> shareQuota({
    required double kwh,
    required String slotLabel,
    String? note,
  }) async {
    final me = _now.arisan?.members.firstWhere(
      (m) => m.isMe,
      orElse: () => ArisanMember(id: 'me', name: _now.profile?.name ?? 'Saya'),
    );
    final offer = QuotaOffer(
      id: _id('off'),
      ownerId: me?.id ?? 'me',
      ownerName: me?.name ?? _now.profile?.name ?? 'Saya',
      amountKwh: kwh,
      slotLabel: slotLabel,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      status: 'open',
      createdAt: DateTime.now(),
    );

    var next = _now.copyWith(offers: [offer, ..._now.offers]);
    if (me != null && _now.arisan != null) {
      next = next.copyWith(
        ledger: [
          LedgerEntry(
            id: _id('led'),
            type: 'quotaShared',
            memberId: me.id,
            memberName: me.name,
            amountKwh: kwh,
            at: DateTime.now(),
            note: offer.note,
          ),
          ..._now.ledger,
        ],
      );
    }
    await _commit(next);
    return offer;
  }

  /// Marks an offer as taken by [takenByName] and records it in the ledger.
  Future<void> markOfferTaken(String offerId, String takenByName) {
    final idx = _now.offers.indexWhere((o) => o.id == offerId);
    if (idx < 0) return Future.value();
    final offer = _now.offers[idx];
    if (offer.status != 'open') return Future.value();

    final offers = [..._now.offers]
      ..[idx] = offer.copyWith(status: 'taken', takenByName: takenByName);

    return _commit(
      _now.copyWith(
        offers: offers,
        ledger: [
          LedgerEntry(
            id: _id('led'),
            type: 'quotaReceived',
            memberId: offer.ownerId,
            memberName: takenByName,
            amountKwh: offer.amountKwh,
            at: DateTime.now(),
            note: 'Dari ${offer.ownerName}',
          ),
          ..._now.ledger,
        ],
      ),
    );
  }

  Future<void> cancelOffer(String offerId) {
    final idx = _now.offers.indexWhere((o) => o.id == offerId);
    if (idx < 0) return Future.value();
    final offers = [..._now.offers]
      ..[idx] = _now.offers[idx].copyWith(status: 'cancelled');
    return _commit(_now.copyWith(offers: offers));
  }

  // -- Saved calculations ---------------------------------------------------

  Future<void> saveCalculation({
    required String label,
    required int principalIdr,
    required int tenorMonths,
    required double monthlyRatePct,
  }) => _commit(
    _now.copyWith(
      calculations: [
        SavedCalculation(
          id: _id('calc'),
          label: label,
          principalIdr: principalIdr,
          tenorMonths: tenorMonths,
          monthlyRatePct: monthlyRatePct,
          savedAt: DateTime.now(),
        ),
        ..._now.calculations,
      ],
    ),
  );

  Future<void> deleteCalculation(String id) => _commit(
    _now.copyWith(
      calculations: _now.calculations.where((c) => c.id != id).toList(),
    ),
  );

  // -- Notifications --------------------------------------------------------

  Future<void> markNotificationsRead(Iterable<String> ids) => _commit(
    _now.copyWith(readNotificationIds: {..._now.readNotificationIds, ...ids}),
  );

  // -- Whole-document operations -------------------------------------------

  /// Replaces everything with [data]. Used by "load sample data" and by a
  /// future restore-from-backup.
  Future<void> replaceAll(AppData data) => _commit(data);

  /// Erases every record, including the profile — the app returns to
  /// onboarding.
  Future<void> clearAll() async {
    state = const AsyncData(AppData.empty);
    await _store.clear();
  }
}
