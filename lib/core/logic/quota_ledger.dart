/// A member's hub quota for a month: what the cooperative allots (35 kWh by
/// default), minus what she used and has booked and gave away, plus what she
/// received from other members.
///
/// "Used" is a hub session that was approved and recorded; "reserved" is booked
/// but not used yet. Both come off what is left straight away, so a booking
/// shows in her balance the moment she makes it and a session never counts
/// twice.
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
    this.usedKwh = 0,
  });

  final double allocationKwh;

  /// Everything counted against the month: used plus reserved.
  final double bookedKwh;
  final double givenKwh;
  final double receivedKwh;

  /// The part of [bookedKwh] already used (sessions recorded by the hub).
  final double usedKwh;

  /// The part of [bookedKwh] booked or waiting for verification, not used yet.
  double get reservedKwh => bookedKwh - usedKwh;

  /// What she could still book this month.
  double get availableKwh => allocationKwh - bookedKwh - givenKwh + receivedKwh;

  /// Her month in total: the allocation, what she gave away and received.
  double get totalKwh => allocationKwh - givenKwh + receivedKwh;

  /// Share of the allowance (plus what she received) already used, reserved
  /// or given away, 0–1.
  double get usedFraction {
    final pool = allocationKwh + receivedKwh;
    return pool <= 0 ? 1 : ((bookedKwh + givenKwh) / pool).clamp(0.0, 1.0);
  }
}

QuotaBalance quotaBalance({
  required String userId,
  required DateTime month,
  required double allocationKwh,
  required Iterable<HubBooking> bookings,
  required Iterable<QuotaOffer> offers,
}) {
  final mine = bookings
      .where(
        (b) =>
            b.userId == userId &&
            b.countsAgainstCapacity &&
            sameMonth(b.bookingDate, month),
      )
      .toList();
  final booked = mine.fold<double>(0, (s, b) => s + b.estKwh);
  final used = mine
      .where((b) => b.status == BookingStatus.completed)
      .fold<double>(0, (s, b) => s + b.estKwh);

  final completed = offers.where(
    (o) => o.status == QuotaStatus.completed && sameMonth(o.updatedAt, month),
  );

  return QuotaBalance(
    allocationKwh: allocationKwh,
    bookedKwh: booked,
    usedKwh: used,
    givenKwh: completed
        .where((o) => o.giverId == userId)
        .fold(0, (s, o) => s + o.kwh),
    receivedKwh: completed
        .where((o) => o.receiverId == userId)
        .fold(0, (s, o) => s + o.kwh),
  );
}

/// Energy a member used on [day]: her sessions that day the hub has recorded.
double usedOnDay({
  required String userId,
  required DateTime day,
  required Iterable<HubBooking> bookings,
}) => bookings
    .where(
      (b) =>
          b.userId == userId &&
          b.status == BookingStatus.completed &&
          sameDay(b.bookingDate, day),
    )
    .fold<double>(0, (s, b) => s + b.estKwh);

/// Where a member stands in her month: days left (counting today) and what she
/// could use per day to make what is left last.
@immutable
class QuotaPace {
  const QuotaPace({
    required this.daysLeft,
    required this.lastDay,
    required this.perDayKwh,
  });

  /// Days from [now] to the end of the month, today included.
  final int daysLeft;
  final DateTime lastDay;

  /// What is left divided over [daysLeft]; zero once nothing is left.
  final double perDayKwh;
}

QuotaPace quotaPace({required DateTime now, required double availableKwh}) {
  final last = DateTime(now.year, now.month + 1, 0);
  final left = last.day - now.day + 1;
  return QuotaPace(
    daysLeft: left,
    lastDay: last,
    perDayKwh: availableKwh <= 0 || left <= 0 ? 0 : availableKwh / left,
  );
}
