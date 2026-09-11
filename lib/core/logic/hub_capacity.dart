/// How much of the shared hub is left, per slot and per day.
///
/// A hub's daily capacity is split across its slots following the sun's arc
/// between 06.00 and 18.00: a midday slot gets more of the day's energy than
/// an early-morning one. That split is an ASSUMPTION stated on the booking
/// screen; the admin sets the daily total.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../db/row.dart';
import '../models/solar.dart';

/// Relative solar energy between two hours, from a sine arc over 06–18.
double solarWeight(int startHour, int endHour) {
  double sum = 0;
  for (double h = startHour.toDouble(); h < endHour; h += 0.25) {
    final mid = h + 0.125;
    if (mid > 6 && mid < 18) sum += math.sin(math.pi * (mid - 6) / 12) * 0.25;
  }
  return sum;
}

@immutable
class SlotAvailability {
  const SlotAvailability({
    required this.slot,
    required this.capacityKwh,
    required this.bookedKwh,
  });

  final HubSlot slot;
  final double capacityKwh;
  final double bookedKwh;

  double get remainingKwh => math.max(0, capacityKwh - bookedKwh);
  bool get isFull => remainingKwh < 0.05;
  double get usedFraction =>
      capacityKwh <= 0 ? 1 : (bookedKwh / capacityKwh).clamp(0, 1);
}

List<SlotAvailability> slotAvailability({
  required SolarHub hub,
  required List<HubSlot> slots,
  required Iterable<HubBooking> bookings,
  required DateTime date,
}) {
  final ordered = [...slots]..sort((a, b) => a.sort.compareTo(b.sort));
  final weights = [
    for (final s in ordered) solarWeight(s.startHour, s.endHour),
  ];
  final total = weights.fold<double>(0, (a, b) => a + b);

  return [
    for (int i = 0; i < ordered.length; i++)
      SlotAvailability(
        slot: ordered[i],
        capacityKwh: total <= 0
            ? hub.dailyCapacityKwh / ordered.length
            : hub.dailyCapacityKwh * weights[i] / total,
        bookedKwh: bookings
            .where(
              (b) =>
                  b.slotId == ordered[i].id &&
                  b.countsAgainstCapacity &&
                  sameDay(b.bookingDate, date),
            )
            .fold<double>(0, (s, b) => s + b.estKwh),
      ),
  ];
}

@immutable
class DayCapacity {
  const DayCapacity({required this.capacityKwh, required this.bookedKwh});

  final double capacityKwh;
  final double bookedKwh;

  double get remainingKwh => math.max(0, capacityKwh - bookedKwh);

  /// Share still free, 0–1 — "Kapasitas energi hari ini".
  double get freeFraction =>
      capacityKwh <= 0 ? 0 : (remainingKwh / capacityKwh).clamp(0, 1);
}

DayCapacity dayCapacity(List<SlotAvailability> slots) => DayCapacity(
  capacityKwh: slots.fold(0, (s, x) => s + x.capacityKwh),
  bookedKwh: slots.fold(0, (s, x) => s + x.bookedKwh),
);

/// The slot with the most room left that can still fit [neededKwh]. Ties go
/// to the sunnier slot, then the earlier one.
SlotAvailability? recommendSlot(
  List<SlotAvailability> slots,
  double neededKwh,
) {
  SlotAvailability? best;
  for (final s in slots) {
    if (s.remainingKwh + 1e-9 < neededKwh) continue;
    if (best == null ||
        s.remainingKwh > best.remainingKwh + 1e-9 ||
        ((s.remainingKwh - best.remainingKwh).abs() < 1e-9 &&
            s.capacityKwh > best.capacityKwh)) {
      best = s;
    }
  }
  return best;
}
