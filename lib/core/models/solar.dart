import 'package:flutter/foundation.dart';

import '../db/row.dart';
import '../l10n/l10n.dart';

@immutable
class SolarHub {
  const SolarHub({
    required this.id,
    required this.cooperativeId,
    required this.name,
    required this.location,
    required this.dailyCapacityKwh,
    required this.createdAt,
  });

  final String id;
  final String cooperativeId;
  final String name;
  final String location;

  /// Set by the admin from the installation's rating. Zero means the admin
  /// has not configured the hub yet — bookings stay closed until they do.
  final double dailyCapacityKwh;
  final DateTime createdAt;

  bool get isConfigured => dailyCapacityKwh > 0;

  SolarHub copyWith({
    String? name,
    String? location,
    double? dailyCapacityKwh,
  }) => SolarHub(
    id: id,
    cooperativeId: cooperativeId,
    name: name ?? this.name,
    location: location ?? this.location,
    dailyCapacityKwh: dailyCapacityKwh ?? this.dailyCapacityKwh,
    createdAt: createdAt,
  );

  factory SolarHub.fromRow(Map<String, dynamic> r) => SolarHub(
    id: rStr(r, 'id'),
    cooperativeId: rStr(r, 'cooperative_id'),
    name: rStr(r, 'name'),
    location: rStr(r, 'location'),
    dailyCapacityKwh: rDbl(r, 'daily_capacity_kwh'),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'cooperative_id': cooperativeId,
    'name': name,
    'location': location,
    'daily_capacity_kwh': dailyCapacityKwh,
    'created_at': ts(createdAt),
  };
}

@immutable
class HubSlot {
  const HubSlot({
    required this.id,
    required this.hubId,
    required this.startHour,
    required this.endHour,
    required this.sort,
  });

  final String id;
  final String hubId;
  final int startHour;
  final int endHour;
  final int sort;

  int get hours => endHour - startHour;

  String get label =>
      '${startHour.toString().padLeft(2, '0')}.00–'
      '${endHour.toString().padLeft(2, '0')}.00';

  factory HubSlot.fromRow(Map<String, dynamic> r) => HubSlot(
    id: rStr(r, 'id'),
    hubId: rStr(r, 'hub_id'),
    startHour: rInt(r, 'start_hour'),
    endHour: rInt(r, 'end_hour'),
    sort: rInt(r, 'sort'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'hub_id': hubId,
    'start_hour': startHour,
    'end_hour': endHour,
    'sort': sort,
  };
}

enum BookingStatus {
  booked,
  completed,
  cancelled;

  static BookingStatus fromDb(String? v) => switch (v) {
    'completed' => completed,
    'cancelled' => cancelled,
    _ => booked,
  };

  String get db => name;

  String get label => switch (this) {
    booked => 'Terjadwal',
    completed => 'Sudah dipakai',
    cancelled => 'Dibatalkan',
  };

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    booked => l10n.bookingStatusBooked,
    completed => l10n.bookingStatusCompleted,
    cancelled => l10n.bookingStatusCancelled,
  };
}

@immutable
class HubBooking {
  const HubBooking({
    required this.id,
    required this.hubId,
    required this.slotId,
    required this.userId,
    required this.applianceName,
    required this.bookingDate,
    required this.estKwh,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String hubId;
  final String slotId;
  final String userId;
  final String applianceName;
  final DateTime bookingDate;

  /// Appliance watts × slot hours, reserved against the slot's capacity.
  final double estKwh;
  final BookingStatus status;
  final DateTime createdAt;

  bool get countsAgainstCapacity => status != BookingStatus.cancelled;

  factory HubBooking.fromRow(Map<String, dynamic> r) => HubBooking(
    id: rStr(r, 'id'),
    hubId: rStr(r, 'hub_id'),
    slotId: rStr(r, 'slot_id'),
    userId: rStr(r, 'user_id'),
    applianceName: rStr(r, 'appliance_name'),
    bookingDate: dayOf(rDate(r, 'booking_date')),
    estKwh: rDbl(r, 'est_kwh'),
    status: BookingStatus.fromDb(rStrN(r, 'status')),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'hub_id': hubId,
    'slot_id': slotId,
    'user_id': userId,
    'appliance_name': applianceName,
    'booking_date': dateOnly(bookingDate),
    'est_kwh': estKwh,
    'status': status.db,
    'created_at': ts(createdAt),
  };
}
