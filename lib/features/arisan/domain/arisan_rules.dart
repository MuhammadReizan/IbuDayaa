/// Arisan Energi domain rules (DATA_MODEL.md §3.10).
///
/// Pure validation for quota-sharing operations. These functions are the
/// single source of truth for "is this operation allowed?" — the repository /
/// session notifier calls them before mutating state, so an invalid operation
/// is rejected regardless of whether the UI validated it first.
library;

import '../../../core/demo/demo_scenario.dart';

// ---------------------------------------------------------------------------
// shareQuota
// ---------------------------------------------------------------------------

/// Why a [shareQuota] call was rejected.
enum ShareQuotaError {
  /// kWh <= 0.
  nonPositiveAmount,

  /// kWh is greater than the member's available quota.
  exceedsAvailable,
}

extension ShareQuotaErrorMessage on ShareQuotaError {
  String get message => switch (this) {
    ShareQuotaError.nonPositiveAmount => 'Jumlah kuota harus lebih dari 0 kWh.',
    ShareQuotaError.exceedsAvailable => 'Jumlah melebihi kuota yang tersedia.',
  };
}

/// Result of a share-quota attempt. Exactly one of [offer] / [error] is set.
class ShareQuotaOutcome {
  const ShareQuotaOutcome._({this.offer, this.error});

  const ShareQuotaOutcome.success(DemoQuotaOffer offer) : this._(offer: offer);
  const ShareQuotaOutcome.failure(ShareQuotaError error) : this._(error: error);

  final DemoQuotaOffer? offer;
  final ShareQuotaError? error;

  bool get isSuccess => error == null;
}

/// Returns the reason [kwh] cannot be shared against [availableKwh], or `null`
/// when the operation is valid. Never clamps — an out-of-range amount is
/// rejected outright.
ShareQuotaError? validateShareQuota({
  required double kwh,
  required double availableKwh,
}) {
  if (kwh <= 0) return ShareQuotaError.nonPositiveAmount;
  if (kwh > availableKwh) return ShareQuotaError.exceedsAvailable;
  return null;
}

// ---------------------------------------------------------------------------
// takeOffer
// ---------------------------------------------------------------------------

/// Why a [takeOffer] call was rejected.
enum TakeOfferError {
  /// No offer with the given id exists (seeded or session).
  unknownOffer,

  /// The offer is not in the `open` state (cancelled / expired).
  notOpen,

  /// The offer has already been taken.
  alreadyTaken,

  /// The offer belongs to the current user.
  ownOffer,

  /// The current user does not need any quota.
  noQuotaNeeded,

  /// This offer was already taken by the current user in this session
  /// (guards against double-tap).
  duplicateTake,
}

extension TakeOfferErrorMessage on TakeOfferError {
  String get message => switch (this) {
    TakeOfferError.unknownOffer => 'Penawaran tidak ditemukan.',
    TakeOfferError.notOpen => 'Penawaran ini sudah tidak tersedia.',
    TakeOfferError.alreadyTaken => 'Penawaran ini sudah diambil.',
    TakeOfferError.ownOffer => 'Anda tidak dapat mengambil penawaran sendiri.',
    TakeOfferError.noQuotaNeeded => 'Anda tidak membutuhkan kuota tambahan.',
    TakeOfferError.duplicateTake => 'Penawaran ini sudah Anda ambil.',
  };
}

/// Result of a take-offer attempt. Exactly one of [offer] / [error] is set.
class TakeOfferOutcome {
  const TakeOfferOutcome._({this.offer, this.error});

  const TakeOfferOutcome.success(DemoQuotaOffer offer) : this._(offer: offer);
  const TakeOfferOutcome.failure(TakeOfferError error) : this._(error: error);

  final DemoQuotaOffer? offer;
  final TakeOfferError? error;

  bool get isSuccess => error == null;
}

/// Returns the reason [offer] cannot be taken by the current user, or `null`
/// when the operation is valid.
TakeOfferError? validateTakeOffer({
  required DemoQuotaOffer? offer,
  required String currentUserId,
  required double neededKwh,
  required bool alreadyRequested,
}) {
  if (offer == null) return TakeOfferError.unknownOffer;
  if (alreadyRequested) return TakeOfferError.duplicateTake;
  if (offer.status == 'taken') return TakeOfferError.alreadyTaken;
  if (offer.status != 'open') return TakeOfferError.notOpen;
  if (offer.ownerMemberId == currentUserId) return TakeOfferError.ownOffer;
  if (neededKwh <= 0) return TakeOfferError.noQuotaNeeded;
  return null;
}
