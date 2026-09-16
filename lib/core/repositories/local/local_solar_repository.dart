import '../../db/ids.dart';
import '../../db/row.dart';
import '../../db/tables.dart';
import '../../errors.dart';
import '../../logic/hub_capacity.dart';
import '../../logic/quota_ledger.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'local_base.dart';

class LocalSolarRepository extends LocalRepo implements SolarRepository {
  LocalSolarRepository(super.db, super.now);

  static const int bookingWindowDays = 14;

  SolarHub _hub(String id) {
    final row = db.find(Tbl.solarHubs, id);
    if (row == null) throw const AppException('Solar Hub tidak ditemukan.');
    return SolarHub.fromRow(row);
  }

  @override
  Future<SolarHub> updateHub(Profile admin, SolarHub hub) async {
    final current = _hub(hub.id);
    requireAdmin(admin, current.cooperativeId);
    if (hub.name.trim().isEmpty) {
      throw const AppException('Nama hub wajib diisi.');
    }
    if (hub.dailyCapacityKwh < 0 || hub.dailyCapacityKwh > 100000) {
      throw const AppException('Kapasitas harian tidak masuk akal.');
    }
    await db.update(Tbl.solarHubs, hub.id, {
      'name': hub.name.trim(),
      'location': hub.location.trim(),
      'daily_capacity_kwh': hub.dailyCapacityKwh,
      'weather_adm4_code': hub.weatherAdm4Code?.trim().isEmpty ?? true
          ? null
          : hub.weatherAdm4Code!.trim(),
    });
    return _hub(hub.id);
  }

  @override
  Future<HubSlot> addSlot(
    Profile admin,
    String hubId,
    int startHour,
    int endHour,
  ) async {
    requireAdmin(admin, _hub(hubId).cooperativeId);
    if (startHour < 5 || endHour > 19 || endHour <= startHour) {
      throw const AppException('Jam slot harus di antara 05.00 dan 19.00.');
    }
    final slots = db
        .select(Tbl.hubSlots, (r) => r['hub_id'] == hubId)
        .map(HubSlot.fromRow)
        .toList();
    final overlaps = slots.any(
      (s) => startHour < s.endHour && endHour > s.startHour,
    );
    if (overlaps) {
      throw const AppException('Slot ini bertabrakan dengan slot lain.');
    }
    final slot = HubSlot(
      id: newId(),
      hubId: hubId,
      startHour: startHour,
      endHour: endHour,
      sort: startHour,
    );
    await db.insert(Tbl.hubSlots, slot.toRow());
    return slot;
  }

  @override
  Future<void> removeSlot(Profile admin, String slotId) async {
    final row = db.find(Tbl.hubSlots, slotId);
    if (row == null) throw const AppException('Slot tidak ditemukan.');
    final slot = HubSlot.fromRow(row);
    requireAdmin(admin, _hub(slot.hubId).cooperativeId);
    final today = dayOf(now());
    final upcoming = db.first(
      Tbl.hubBookings,
      (r) =>
          r['slot_id'] == slotId &&
          r['status'] == 'booked' &&
          !dayOf(rDate(r, 'booking_date')).isBefore(today),
    );
    if (upcoming != null) {
      throw const AppException(
        'Masih ada booking di slot ini. Batalkan atau tunggu sampai selesai.',
      );
    }
    await db.delete(Tbl.hubSlots, slotId);
  }

  @override
  Future<HubBooking> book({
    required Profile me,
    required String slotId,
    required DateTime date,
    required String applianceName,
    required double estKwh,
  }) async {
    requireMember(me);
    final slotRow = db.find(Tbl.hubSlots, slotId);
    if (slotRow == null) throw const AppException('Slot tidak ditemukan.');
    final slot = HubSlot.fromRow(slotRow);
    final hub = _hub(slot.hubId);
    if (hub.cooperativeId != me.cooperativeId) {
      throw const AppException('Slot ini bukan milik koperasi Anda.');
    }
    if (!hub.isConfigured) {
      throw const AppException(
        'Kapasitas Solar Hub belum diatur admin. Booking belum bisa dibuka.',
      );
    }
    if (estKwh <= 0) throw const AppException('Pilih alat yang akan dipakai.');

    final today = dayOf(now());
    final day = dayOf(date);
    if (day.isBefore(today) ||
        day.isAfter(today.add(const Duration(days: bookingWindowDays)))) {
      throw const AppException(
        'Booking hanya bisa untuk hari ini sampai 14 hari ke depan.',
      );
    }
    if (sameDay(day, today) && now().hour >= slot.endHour) {
      throw const AppException('Slot ini sudah lewat untuk hari ini.');
    }

    final bookings = db
        .select(Tbl.hubBookings, (r) => r['hub_id'] == hub.id)
        .map(HubBooking.fromRow)
        .toList();
    final slots = db
        .select(Tbl.hubSlots, (r) => r['hub_id'] == hub.id)
        .map(HubSlot.fromRow)
        .toList();
    final availability = slotAvailability(
      hub: hub,
      slots: slots,
      bookings: bookings,
      date: day,
    ).firstWhere((a) => a.slot.id == slotId);
    if (availability.remainingKwh + 1e-9 < estKwh) {
      throw AppException(
        'Kapasitas slot ${slot.label} tinggal '
        '${availability.remainingKwh.toStringAsFixed(1)} kWh. Pilih slot lain.',
      );
    }

    final coop = cooperativeById(me.cooperativeId);
    final balance = quotaBalance(
      userId: me.id,
      month: day,
      allocationKwh: coop.memberMonthlyQuotaKwh,
      bookings: bookings,
      offers: db
          .select(Tbl.quotaOffers, (r) => r['cooperative_id'] == coop.id)
          .map(QuotaOffer.fromRow),
    );
    if (balance.availableKwh + 1e-9 < estKwh) {
      throw AppException(
        'Kuota energi Anda bulan ini tinggal '
        '${balance.availableKwh.toStringAsFixed(1)} kWh. Minta kuota ke '
        'anggota lain di menu Perdagangan Energi.',
      );
    }

    final booking = HubBooking(
      id: newId(),
      hubId: hub.id,
      slotId: slotId,
      userId: me.id,
      applianceName: applianceName,
      bookingDate: day,
      estKwh: estKwh,
      status: BookingStatus.booked,
      createdAt: now(),
    );
    await db.insert(Tbl.hubBookings, booking.toRow());
    return booking;
  }

  @override
  Future<void> setBookingStatus(
    Profile actor,
    String bookingId,
    BookingStatus status,
  ) async {
    final row = db.find(Tbl.hubBookings, bookingId);
    if (row == null) throw const AppException('Booking tidak ditemukan.');
    final booking = HubBooking.fromRow(row);
    final hub = _hub(booking.hubId);
    final isOwner = booking.userId == actor.id;
    final isAdmin = actor.isAdmin && actor.cooperativeId == hub.cooperativeId;
    if (!isOwner && !isAdmin) {
      throw const AppException('Anda tidak bisa mengubah booking ini.');
    }
    if (booking.status != BookingStatus.booked) {
      throw const AppException('Booking ini sudah selesai atau dibatalkan.');
    }
    if (status == BookingStatus.completed &&
        booking.bookingDate.isAfter(dayOf(now()))) {
      throw const AppException(
        'Pemakaian baru bisa dikonfirmasi pada atau setelah hari booking.',
      );
    }
    await db.update(Tbl.hubBookings, bookingId, {'status': status.db});
  }
}
