import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/credit_score/application/credit_score_provider.dart';
import '../errors.dart';
import '../demo/demo_bill_models.dart';
import '../models/models.dart';
import '../repositories/local/sample_seeder.dart';
import 'app_state.dart';
import 'selectors.dart';

final actionsProvider = Provider<AppActions>((ref) => AppActions(ref));

/// Every mutation the UI can make. Each one calls a repository, then reloads
/// the snapshot so all screens see the change. Repository errors surface as
/// [AppException] with a message ready to show.
class AppActions {
  AppActions(this._ref);

  final Ref _ref;

  Profile get _me {
    final me = _ref.read(appStateProvider).me;
    if (me == null) throw const AppException('Silakan masuk terlebih dahulu.');
    return me;
  }

  DateTime get _now => _ref.read(clockProvider)();
  AppStateController get _state => _ref.read(appStateProvider.notifier);
  Future<void> _refresh() => _state.refresh();

  // -- Account ---------------------------------------------------------------

  Future<Cooperative?> findCooperative(String code) =>
      _ref.read(authRepositoryProvider).findCooperativeByInviteCode(code);

  Future<void> login(String phone, String pin) async {
    final me = await _ref
        .read(authRepositoryProvider)
        .login(phone: phone, pin: pin);
    await _state.enter(me);
    await _recordScoreSnapshot();
  }

  Future<void> registerMember({
    required String phone,
    required String pin,
    required String fullName,
    required String businessName,
    required String city,
    required String inviteCode,
  }) async {
    final me = await _ref
        .read(authRepositoryProvider)
        .registerMember(
          phone: phone,
          pin: pin,
          fullName: fullName,
          businessName: businessName,
          city: city,
          inviteCode: inviteCode,
        );
    await _state.enter(me);
  }

  Future<void> registerAdmin({
    required String phone,
    required String pin,
    required String fullName,
    required String city,
    required String cooperativeName,
  }) async {
    final me = await _ref
        .read(authRepositoryProvider)
        .registerAdmin(
          phone: phone,
          pin: pin,
          fullName: fullName,
          city: city,
          cooperativeName: cooperativeName,
        );
    await _state.enter(me);
  }

  Future<void> logout() async {
    await _ref.read(authRepositoryProvider).logout();
    _state.leave();
  }

  SampleSeeder get _seeder => SampleSeeder(
    _ref.read(localDatabaseProvider),
    _ref.read(clockProvider),
    _ref.read(creditScoringEngineProvider),
  );

  bool get sampleSeeded => _seeder.isSeeded;

  /// Local mode only: adds the clearly-labelled sample cooperative.
  Future<void> seedSample() => _seeder.seed();

  /// Local mode only: erases every account and record on this phone.
  Future<void> resetDevice() async {
    await _ref.read(localDatabaseProvider).wipe();
    _state.leave();
  }

  Future<void> changePin(String current, String next) => _ref
      .read(authRepositoryProvider)
      .changePin(userId: _me.id, currentPin: current, newPin: next);

  Future<void> updateProfile(Profile profile) async {
    await _ref.read(authRepositoryProvider).updateProfile(profile);
    await _refresh();
  }

  // -- Energy ----------------------------------------------------------------

  Future<EnergyRecord> saveRecord({
    required EnergyKind kind,
    required DateTime periodMonth,
    required double kwh,
    required int totalIdr,
    String? customerId,
    String? photoPath,
    required RecordSource source,
    String? replaceId,
  }) async {
    final r = await _ref
        .read(energyRepositoryProvider)
        .saveRecord(
          me: _me,
          kind: kind,
          periodMonth: periodMonth,
          kwh: kwh,
          totalIdr: totalIdr,
          customerId: customerId,
          photoPath: photoPath,
          source: source,
          replaceId: replaceId,
        );
    await _refresh();
    await _recordScoreSnapshot();
    return r;
  }

  Future<void> deleteRecord(String id) async {
    await _ref.read(energyRepositoryProvider).deleteRecord(_me, id);
    await _refresh();
  }

  Future<void> saveAppliance({
    String? id,
    required String name,
    required String kind,
    required double watts,
    required double hoursPerDay,
    required int daysPerWeek,
  }) async {
    await _ref
        .read(energyRepositoryProvider)
        .saveAppliance(
          me: _me,
          id: id,
          name: name,
          kind: kind,
          watts: watts,
          hoursPerDay: hoursPerDay,
          daysPerWeek: daysPerWeek,
        );
    await _refresh();
  }

  Future<void> deleteAppliance(String id) async {
    await _ref.read(energyRepositoryProvider).deleteAppliance(_me, id);
    await _refresh();
  }

  Future<RoofAssessment> saveRoofAssessment(RoofAssessment draft) async {
    final saved = await _ref
        .read(energyRepositoryProvider)
        .saveRoofAssessment(_me, draft);
    await _refresh();
    return saved;
  }

  /// Demo/testing only: seeds bill history, an appliance list, and the
  /// current month's bill from a scanned demo barcode, so the real spike
  /// check and per-appliance cost breakdown (`energy_insights.dart`) have
  /// something to compute from instead of a hand-typed month of data before
  /// every demo. Every number comes from the barcode's matched entry; this
  /// computes nothing itself. Unlike a real scan, the barcode is a
  /// deterministic lookup rather than a probabilistic OCR read, so the
  /// caller goes straight to the analysis screen instead of the editable
  /// confirm screen.
  Future<void> applyDemoBillPayload(DemoBillPayload payload) async {
    // Step 1: Save all historical bill records (upsert by month, safe to repeat).
    for (final h in payload.history) {
      await saveRecord(
        kind: EnergyKind.postpaid,
        periodMonth: h.month,
        kwh: h.kwh,
        totalIdr: h.totalIdr,
        source: RecordSource.manual,
      );
    }

    // Step 2: Clear ALL existing appliances so each demo barcode produces
    // a clean, unique appliance set. Without this, a second scan would skip
    // appliances already inserted from a previous demo (e.g. "Kulkas" from
    // DEMO-001 blocks DEMO-002's "Kulkas" with different wattage), causing
    // all demos to show identical analysis results.
    final existingAppliances = _ref
        .read(appStateProvider)
        .data
        .appliancesOf(_me.id);
    for (final a in existingAppliances) {
      await _ref.read(energyRepositoryProvider).deleteAppliance(_me, a.id);
    }
    await _refresh();

    // Step 3: Insert the demo payload's appliances fresh.
    for (final a in payload.appliances) {
      await saveAppliance(
        name: a.name,
        kind: a.kind,
        watts: a.watts,
        hoursPerDay: a.hoursPerDay,
        daysPerWeek: a.daysPerWeek,
      );
    }

    // Step 4: Save the current month's bill record.
    await saveRecord(
      kind: EnergyKind.postpaid,
      periodMonth: payload.current.month,
      kwh: payload.current.kwh,
      totalIdr: payload.current.totalIdr,
      source: RecordSource.scan,
    );
  }

  // -- Solar hub -------------------------------------------------------------

  Future<HubBooking> book({
    required String slotId,
    required DateTime date,
    required String applianceName,
    required double estKwh,
  }) async {
    final b = await _ref
        .read(solarRepositoryProvider)
        .book(
          me: _me,
          slotId: slotId,
          date: date,
          applianceName: applianceName,
          estKwh: estKwh,
        );
    await _refresh();
    return b;
  }

  Future<void> setBookingStatus(String id, BookingStatus status) async {
    await _ref.read(solarRepositoryProvider).setBookingStatus(_me, id, status);
    await _refresh();
    await _recordScoreSnapshot();
  }

  Future<void> updateHub(SolarHub hub) async {
    await _ref.read(solarRepositoryProvider).updateHub(_me, hub);
    await _refresh();
  }

  Future<void> addSlot(String hubId, int start, int end) async {
    await _ref.read(solarRepositoryProvider).addSlot(_me, hubId, start, end);
    await _refresh();
  }

  Future<void> removeSlot(String slotId) async {
    await _ref.read(solarRepositoryProvider).removeSlot(_me, slotId);
    await _refresh();
  }

  // -- Arisan & quota --------------------------------------------------------

  Future<void> createGroup({
    required String name,
    required int contributionIdr,
    required DateTime startMonth,
    required List<String> memberIds,
  }) async {
    await _ref
        .read(arisanRepositoryProvider)
        .createGroup(
          admin: _me,
          name: name,
          contributionIdr: contributionIdr,
          startMonth: startMonth,
          memberIdsInTurnOrder: memberIds,
        );
    await _refresh();
  }

  Future<void> submitContribution(String groupId, {String? note}) async {
    await _ref
        .read(arisanRepositoryProvider)
        .submitContribution(
          me: _me,
          groupId: groupId,
          periodMonth: _now,
          note: note,
        );
    await _refresh();
  }

  Future<void> reviewPayment(
    String id, {
    required bool approve,
    String? note,
  }) async {
    await _ref
        .read(arisanRepositoryProvider)
        .reviewPayment(admin: _me, paymentId: id, approve: approve, note: note);
    await _refresh();
  }

  Future<void> recordPayout(String groupId, String userId) async {
    await _ref
        .read(arisanRepositoryProvider)
        .recordPayout(
          admin: _me,
          groupId: groupId,
          userId: userId,
          periodMonth: _now,
        );
    await _refresh();
  }

  Future<QuotaOffer> postQuota({
    required QuotaKind kind,
    required double kwh,
    required String slotNote,
    String? note,
  }) async {
    final o = await _ref
        .read(arisanRepositoryProvider)
        .postQuota(
          me: _me,
          kind: kind,
          kwh: kwh,
          slotNote: slotNote,
          note: note,
        );
    await _refresh();
    return o;
  }

  Future<void> respondToQuota(String offerId) async {
    await _ref
        .read(arisanRepositoryProvider)
        .respondToQuota(me: _me, offerId: offerId);
    await _refresh();
  }

  Future<void> settleQuota(String offerId, {required bool accept}) async {
    await _ref
        .read(arisanRepositoryProvider)
        .settleQuota(me: _me, offerId: offerId, accept: accept);
    await _refresh();
    await _recordScoreSnapshot();
  }

  Future<void> cancelQuota(String offerId) async {
    await _ref
        .read(arisanRepositoryProvider)
        .cancelQuota(me: _me, offerId: offerId);
    await _refresh();
  }

  // -- Loans -----------------------------------------------------------------

  Future<LoanApplication> submitLoan({
    required int amountIdr,
    required LoanPurpose purpose,
    required int tenorMonths,
    String? note,
  }) async {
    final l = await _ref
        .read(loanRepositoryProvider)
        .submit(
          me: _me,
          amountIdr: amountIdr,
          purpose: purpose,
          tenorMonths: tenorMonths,
          note: note,
        );
    await _refresh();
    return l;
  }

  Future<void> cancelLoan(String id) async {
    await _ref.read(loanRepositoryProvider).cancel(me: _me, loanId: id);
    await _refresh();
  }

  Future<void> startLoanReview(String id) async {
    await _ref.read(loanRepositoryProvider).startReview(admin: _me, loanId: id);
    await _refresh();
  }

  Future<void> approveLoan(String id, {String? note}) async {
    await _ref
        .read(loanRepositoryProvider)
        .approve(admin: _me, loanId: id, note: note);
    await _refresh();
  }

  Future<void> rejectLoan(String id, String reason) async {
    await _ref
        .read(loanRepositoryProvider)
        .reject(admin: _me, loanId: id, reason: reason);
    await _refresh();
  }

  Future<void> disburseLoan(String id) async {
    await _ref.read(loanRepositoryProvider).disburse(admin: _me, loanId: id);
    await _refresh();
  }

  Future<void> markInstallmentPaid(String installmentId) async {
    await _ref
        .read(loanRepositoryProvider)
        .markInstallmentPaid(admin: _me, installmentId: installmentId);
    await _refresh();
  }

  // -- Messages --------------------------------------------------------------

  Future<String> openDirectThread(String otherUserId) async {
    final t = await _ref
        .read(messageRepositoryProvider)
        .directThread(me: _me, otherUserId: otherUserId);
    await _refresh();
    return t.id;
  }

  Future<void> sendMessage(String threadId, String body) async {
    await _ref
        .read(messageRepositoryProvider)
        .send(me: _me, threadId: threadId, body: body);
    await _refresh();
  }

  Future<void> markThreadRead(String threadId) async {
    await _ref
        .read(messageRepositoryProvider)
        .markThreadRead(me: _me, threadId: threadId);
    await _refresh();
  }

  Future<void> markNotificationRead(String id) async {
    await _ref.read(messageRepositoryProvider).markNotificationRead(_me, id);
    await _refresh();
  }

  Future<void> markAllNotificationsRead() async {
    await _ref.read(messageRepositoryProvider).markAllNotificationsRead(_me);
    await _refresh();
  }

  // -- Cooperative -----------------------------------------------------------

  Future<void> updateCooperative(Cooperative coop) async {
    await _ref.read(cooperativeRepositoryProvider).updateSettings(_me, coop);
    await _refresh();
  }

  Future<void> regenerateInviteCode() async {
    await _ref.read(cooperativeRepositoryProvider).regenerateInviteCode(_me);
    await _refresh();
  }

  // --------------------------------------------------------------------------

  Future<void> _recordScoreSnapshot() async {
    final state = _ref.read(appStateProvider);
    final me = state.me;
    if (me == null || me.isAdmin) return;
    final score = state.data.scoreOf(
      me.id,
      _now,
      _ref.read(creditScoringEngineProvider),
    );
    if (score == null) return;
    await _ref.read(scoreRepositoryProvider).recordMonthlySnapshot(me, score);
    await _refresh();
  }
}
