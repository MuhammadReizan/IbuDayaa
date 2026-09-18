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
    this.weatherAdm4Code,
    this.maxLoadKw = 0,
  });

  final String id;
  final String cooperativeId;
  final String name;
  final String location;

  /// What the inverter can carry at the same moment (kW). Set by the admin
  /// from the installation; zero means not set, so simultaneous load is not
  /// checked. Energy (kWh) says how much the hub can give in a day; this says
  /// how many heavy appliances can run together without tripping it.
  final double maxLoadKw;

  /// Set by the admin from the installation's rating. Zero means the admin
  /// has not configured the hub yet — bookings stay closed until they do.
  final double dailyCapacityKwh;
  final DateTime createdAt;

  /// BMKG's `adm4` (village-level) region code for this hub's location,
  /// e.g. "16.71.05.1001" — set by the admin so the Solar Hub screen can
  /// show a real weather-derived production window (see
  /// lib/core/weather/). Null/empty means the panel stays hidden; this
  /// feature is opt-in and never blocks booking or capacity.
  final String? weatherAdm4Code;

  bool get isConfigured => dailyCapacityKwh > 0;

  SolarHub copyWith({
    String? name,
    String? location,
    double? dailyCapacityKwh,
    String? weatherAdm4Code,
    double? maxLoadKw,
  }) => SolarHub(
    id: id,
    cooperativeId: cooperativeId,
    name: name ?? this.name,
    location: location ?? this.location,
    dailyCapacityKwh: dailyCapacityKwh ?? this.dailyCapacityKwh,
    createdAt: createdAt,
    weatherAdm4Code: weatherAdm4Code ?? this.weatherAdm4Code,
    maxLoadKw: maxLoadKw ?? this.maxLoadKw,
  );

  factory SolarHub.fromRow(Map<String, dynamic> r) => SolarHub(
    id: rStr(r, 'id'),
    cooperativeId: rStr(r, 'cooperative_id'),
    name: rStr(r, 'name'),
    location: rStr(r, 'location'),
    dailyCapacityKwh: rDbl(r, 'daily_capacity_kwh'),
    createdAt: rDate(r, 'created_at'),
    weatherAdm4Code: rStrN(r, 'weather_adm4_code'),
    maxLoadKw: rDbl(r, 'max_load_kw'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'cooperative_id': cooperativeId,
    'name': name,
    'location': location,
    'daily_capacity_kwh': dailyCapacityKwh,
    'created_at': ts(createdAt),
    'weather_adm4_code': weatherAdm4Code,
    'max_load_kw': maxLoadKw,
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
    this.isOpen = true,
  });

  final String id;
  final String hubId;
  final int startHour;
  final int endHour;
  final int sort;

  /// An admin can close a slot (maintenance, bad weather). A closed slot takes
  /// no new bookings or QR requests; existing ones are left for the admin.
  final bool isOpen;

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
    isOpen: r['is_open'] != false,
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'hub_id': hubId,
    'start_hour': startHour,
    'end_hour': endHour,
    'sort': sort,
    'is_open': isOpen,
  };
}

enum BookingStatus {
  /// Requested by scanning the hub connection QR code; reserves capacity
  /// but is not usable until an admin approves it (→ [booked]) or rejects
  /// it (→ [cancelled]).
  pendingVerification,
  booked,
  completed,
  cancelled;

  static BookingStatus fromDb(String? v) => switch (v) {
    'pendingVerification' => pendingVerification,
    'completed' => completed,
    'cancelled' => cancelled,
    _ => booked,
  };

  String get db => name;

  String get label => switch (this) {
    pendingVerification => 'Menunggu verifikasi',
    booked => 'Terjadwal',
    completed => 'Sudah dipakai',
    cancelled => 'Dibatalkan',
  };

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    pendingVerification => l10n.bookingStatusPendingVerification,
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
    this.loadKw = 0,
    this.requestedAt,
  });

  final String id;
  final String hubId;
  final String slotId;
  final String userId;
  final String applianceName;
  final DateTime bookingDate;

  /// Appliance watts / 1000 running together in this session — what counts
  /// against the hub's simultaneous-load limit.
  final double loadKw;

  /// When the member scanned the hub QR for this session, if she did.
  final DateTime? requestedAt;

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
    loadKw: rDbl(r, 'load_kw'),
    requestedAt: rDateN(r, 'requested_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'hub_id': hubId,
    'slot_id': slotId,
    'user_id': userId,
    'load_kw': loadKw,
    'requested_at': requestedAt == null ? null : ts(requestedAt!),
    'appliance_name': applianceName,
    'booking_date': dateOnly(bookingDate),
    'est_kwh': estKwh,
    'status': status.db,
    'created_at': ts(createdAt),
  };
}
