/// What Tukar Kuota (virtual quota trading) says about itself: who a member
/// could trade with and what trading did for the whole cooperative. Pure arithmetic over stored rows — every number can
/// be traced to an offer or a booking.
library;

import 'package:flutter/foundation.dart';

import '../db/row.dart';
import '../models/arisan.dart';
import 'quota_ledger.dart';

/// An open offer that fits what a member wants, with why.
@immutable
class QuotaMatch {
  const QuotaMatch({required this.offer, required this.covers});

  final QuotaOffer offer;

  /// For a member who needs quota: the offer alone covers the amount wanted.
  /// For one who shares: the offer asks for no more than she can give.
  final bool covers;
}

/// Open offers a member could trade with, best first. The rule is shown on
/// screen: the amount that fits best comes first, then whoever has waited
/// longest (a fair queue, like an arisan turn).
///
/// [wantKind] is what the member wants to do: [QuotaKind.need] matches her
/// against open shares, [QuotaKind.share] against open needs she can fully
/// fund from [availableKwh].
List<QuotaMatch> matchQuotaOffers({
  required Iterable<QuotaOffer> offers,
  required String myId,
  required QuotaKind wantKind,
  required double wantedKwh,
  required double availableKwh,
}) {
  final wanted = wantedKwh > 0 ? wantedKwh : 0.0;
  final counter = wantKind == QuotaKind.need ? QuotaKind.share : QuotaKind.need;
  final matches = <QuotaMatch>[];
  for (final o in offers) {
    if (o.status != QuotaStatus.open ||
        o.ownerId == myId ||
        o.kind != counter) {
      continue;
    }
    if (wantKind == QuotaKind.share && o.kwh > availableKwh + 1e-9) continue;
    final covers = wantKind == QuotaKind.need
        ? o.kwh + 1e-9 >= wanted
        : o.kwh <= wanted + 1e-9 || wanted == 0;
    matches.add(QuotaMatch(offer: o, covers: covers));
  }
  matches.sort((a, b) {
    if (a.covers != b.covers) return a.covers ? -1 : 1;
    final gap = (a.offer.kwh - wanted).abs().compareTo(
      (b.offer.kwh - wanted).abs(),
    );
    return gap != 0 ? gap : a.offer.createdAt.compareTo(b.offer.createdAt);
  });
  return matches;
}

/// The cooperative's month in Tukar Kuota, for the admin.
@immutable
class QuotaImpact {
  const QuotaImpact({
    required this.tradedKwh,
    required this.trades,
    required this.sharers,
    required this.utilizationPct,
  });

  /// kWh that moved between members this month.
  final double tradedKwh;
  final int trades;

  /// Distinct members who gave quota this month.
  final int sharers;

  /// Booked kWh as a share of all members' allocations (0–100).
  final int utilizationPct;

  bool get hasActivity => trades > 0;
}

QuotaImpact quotaImpact({
  required Iterable<QuotaOffer> offers,
  required Iterable<QuotaBalance> balances,
  required DateTime now,
}) {
  final done = offers
      .where(
        (o) => o.status == QuotaStatus.completed && sameMonth(o.updatedAt, now),
      )
      .toList();
  final allocated = balances.fold<double>(0, (s, b) => s + b.allocationKwh);
  final booked = balances.fold<double>(0, (s, b) => s + b.bookedKwh);
  return QuotaImpact(
    tradedKwh: done.fold<double>(0, (s, o) => s + o.kwh),
    trades: done.length,
    sharers: done.map((o) => o.giverId).whereType<String>().toSet().length,
    utilizationPct: allocated <= 0
        ? 0
        : (booked / allocated * 100).clamp(0, 100).round(),
  );
}
