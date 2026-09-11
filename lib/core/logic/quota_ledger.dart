/// A member's hub quota for a month: what the cooperative allots, minus what
/// she booked and gave away, plus what she received from other members.
library;

import 'package:flutter/foundation.dart';

import '../db/row.dart';
import '../models/arisan.dart';
import '../models/solar.dart';

@immutable
class QuotaBalance {
  const QuotaBalance({
    required this.allocationKwh,
    required this.bookedKwh,
    required this.givenKwh,
    required this.receivedKwh,
  });

  final double allocationKwh;
  final double bookedKwh;
  final double givenKwh;
  final double receivedKwh;

  double get availableKwh => allocationKwh - bookedKwh - givenKwh + receivedKwh;
}

QuotaBalance quotaBalance({
  required String userId,
  required DateTime month,
  required double allocationKwh,
  required Iterable<HubBooking> bookings,
  required Iterable<QuotaOffer> offers,
}) {
  final booked = bookings
      .where(
        (b) =>
            b.userId == userId &&
            b.countsAgainstCapacity &&
            sameMonth(b.bookingDate, month),
      )
      .fold<double>(0, (s, b) => s + b.estKwh);

  final completed = offers.where(
    (o) => o.status == QuotaStatus.completed && sameMonth(o.updatedAt, month),
  );

  return QuotaBalance(
    allocationKwh: allocationKwh,
    bookedKwh: booked,
    givenKwh: completed
        .where((o) => o.giverId == userId)
        .fold(0, (s, o) => s + o.kwh),
    receivedKwh: completed
        .where((o) => o.receiverId == userId)
        .fold(0, (s, o) => s + o.kwh),
  );
}
