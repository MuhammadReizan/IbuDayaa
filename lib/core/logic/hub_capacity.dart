/// How much of the shared hub is left on a day. Three limits, each physical:
///
///  * **Seats** — how many members may hold a booking in one slot
///    (`SolarHub.maxMembersPerSlot`, every slot alike). Seats are what makes a
///    slot "full": one booking never does, however much energy it takes.
///  * **Energy** — what the hub can give in the whole day (kWh). The hub has a
///    battery, so the day's budget is shared across its slots rather than cut
///    into a fixed piece per slot; every booking draws from the same day.
///  * **Load** — what the inverter carries at the same moment (kW), per slot.
///
/// A member's own monthly quota is separate (see `quota_ledger.dart`).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../db/row.dart';
import '../models/solar.dart';

/// Days a month's quota is spread over when sizing the hub.
const int kQuotaMonthDays = 30;

/// The daily capacity at which every member could use her whole monthly quota:
/// [members] × [monthlyQuotaKwh] ÷ 30 days. A planning figure for the admin —
/// booking rules only ever look at the capacity the admin actually set.
double dailyCapacityForQuota({
  required int members,
  required double monthlyQuotaKwh,
}) => members * monthlyQuotaKwh / kQuotaMonthDays;

@immutable
class SlotAvailability {
  const SlotAvailability({
    required this.slot,
    this.bookedMembers = 0,
    this.seatLimit = 0,
    this.bookedKwh = 0,
    this.dayCapacityKwh = 0,
    this.dayBookedKwh = 0,
    this.loadKw = 0,
    this.maxLoadKw = 0,
  });

  final HubSlot slot;

  /// Members holding a booking in this slot that day, and the limit (0 = none).
  final int bookedMembers;
  final int seatLimit;

  /// Energy booked into this slot (information; the limit is the day's).
  final double bookedKwh;

  /// The hub's energy for the whole day and how much of it is booked, across
  /// every slot — the same figures on each slot of that day.
  final double dayCapacityKwh;
  final double dayBookedKwh;

  /// Appliance load already booked into this slot (kW), and the hub's limit
  /// (0 = not set, so not checked).
  final double loadKw;
  final double maxLoadKw;

  bool get isOpen => slot.isOpen;

  bool get hasSeatLimit => seatLimit > 0;
  bool get hasSeat => !hasSeatLimit || bookedMembers < seatLimit;

  /// No seat left. Not the same as no energy left.
  bool get isFull => !hasSeat;
  int get remainingSeats =>
      hasSeatLimit ? math.max(0, seatLimit - bookedMembers) : 0;
  double get seatFraction =>
      hasSeatLimit ? (bookedMembers / seatLimit).clamp(0.0, 1.0) : 0;

  bool get hasLoadLimit => maxLoadKw > 0;
  double get remainingKw =>
      hasLoadLimit ? math.max(0, maxLoadKw - loadKw) : double.infinity;

  /// Whether [kw] more appliance load still fits the inverter in this slot.
  bool fitsLoad(double kw) => !hasLoadLimit || loadKw + kw <= maxLoadKw + 1e-9;

  double get dayRemainingKwh => math.max(0, dayCapacityKwh - dayBookedKwh);

  /// Whether [kwh] more still fits the hub's energy for the day.
  bool fitsKwh(double kwh) => kwh <= dayRemainingKwh + 1e-9;
}

List<SlotAvailability> slotAvailability({
  required SolarHub hub,
  required List<HubSlot> slots,
  required Iterable<HubBooking> bookings,
  required DateTime date,
}) {
  final ordered = [...slots]..sort((a, b) => a.sort.compareTo(b.sort));
  final live = bookings
      .where((b) => b.countsAgainstCapacity && sameDay(b.bookingDate, date))
      .toList();
  final dayBooked = live.fold<double>(0, (s, b) => s + b.estKwh);

  return [
    for (final slot in ordered)
      () {
        final inSlot = live.where((b) => b.slotId == slot.id).toList();
        return SlotAvailability(
          slot: slot,
          bookedMembers: inSlot.map((b) => b.userId).toSet().length,
          seatLimit: hub.maxMembersPerSlot,
          bookedKwh: inSlot.fold<double>(0, (s, b) => s + b.estKwh),
          dayCapacityKwh: hub.dailyCapacityKwh,
          dayBookedKwh: dayBooked,
          loadKw: inSlot.fold<double>(0, (s, b) => s + b.loadKw),
          maxLoadKw: hub.maxLoadKw,
        );
      }(),
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

DayCapacity dayCapacity(List<SlotAvailability> slots) => slots.isEmpty
    ? const DayCapacity(capacityKwh: 0, bookedKwh: 0)
    : DayCapacity(
        capacityKwh: slots.first.dayCapacityKwh,
        bookedKwh: slots.first.dayBookedKwh,
      );

/// The least crowded open slot with a free seat that still fits [neededKwh]
/// (and [neededKw] of simultaneous load). Closed and full slots are skipped.
/// Ties go to the earlier slot.
SlotAvailability? recommendSlot(
  List<SlotAvailability> slots,
  double neededKwh, {
  double neededKw = 0,
}) {
  SlotAvailability? best;
  for (final s in slots) {
    if (!s.isOpen || !s.hasSeat || !s.fitsLoad(neededKw)) continue;
    if (!s.fitsKwh(neededKwh)) continue;
    if (best == null || s.bookedMembers < best.bookedMembers) best = s;
  }
  return best;
}
