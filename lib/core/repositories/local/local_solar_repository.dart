import '../../db/ids.dart';
import '../../hub_qr.dart';
import '../../db/row.dart';
import '../../db/tables.dart';
import '../../errors.dart';
import '../../logic/hub_capacity.dart';
import '../../logic/quota_ledger.dart';
import '../../models/models.dart';
import '../../paths.dart';
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

  SolarHub _hubOfCooperative(String cooperativeId) {
    final row = db.first(
      Tbl.solarHubs,
      (r) => r['cooperative_id'] == cooperativeId,
    );
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

  /// Shared validation + insert for both a scheduled [book] and an
  /// immediate QR [requestConnection] — everything except the date/slot
  /// window checks that only apply to a member picking her own slot ahead
  /// of time.
  Future<HubBooking> _createBooking({
    required Profile me,
    required String slotId,
    required DateTime date,
    required String applianceName,
    required double estKwh,
    required BookingStatus status,
  }) async {
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
      date: date,
    ).firstWhere((a) => a.slot.id == slotId);
    if (availability.remainingKwh + 1e-9 < estKwh) {
      throw AppException(
        'Kapasitas slot ${slot.label} tinggal '
        '${availability.remainingKwh.toStringAsFixed(1)} kWh. Pilih slot lain.',
      );
    }

    final coop = cooperativeById(me.cooperativeId);
    final allocationKwh = me.hubAllocationKwh ?? coop.memberMonthlyQuotaKwh;
    final balance = quotaBalance(
      userId: me.id,
      month: date,
      allocationKwh: allocationKwh,
      bookings: bookings,
      offers: db
          .select(Tbl.quotaOffers, (r) => r['cooperative_id'] == coop.id)
          .map(QuotaOffer.fromRow),
    );
    if (balance.availableKwh + 1e-9 < estKwh) {
      throw AppException(
        'Kuota energi Anda bulan ini tinggal '
        '${balance.availableKwh.toStringAsFixed(1)} kWh. Minta kuota ke '
        'anggota lain di menu Arisan Energi.',
      );
    }

    final booking = HubBooking(
      id: newId(),
      hubId: hub.id,
      slotId: slotId,
      userId: me.id,
      applianceName: applianceName,
      bookingDate: date,
      estKwh: estKwh,
      status: status,
      createdAt: now(),
    );
    await db.insert(Tbl.hubBookings, booking.toRow());
    return booking;
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

    return _createBooking(
      me: me,
      slotId: slotId,
      date: day,
      applianceName: applianceName,
      estKwh: estKwh,
      status: BookingStatus.booked,
    );
  }

  @override
  Future<HubBooking> requestConnection({
    required Profile me,
    required String scannedCode,
    required String applianceName,
    required double estKwh,
  }) async {
    requireMember(me);
    final hub = _hubOfCooperative(me.cooperativeId);
    if (scannedCode.trim().toUpperCase() != kSolarHubQr.toUpperCase()) {
      throw const AppException('QR ini bukan QR Solar Hub koperasi Anda.');
    }

    final slots =
        db
            .select(Tbl.hubSlots, (r) => r['hub_id'] == hub.id)
            .map(HubSlot.fromRow)
            .toList()
          ..sort((a, b) => a.sort.compareTo(b.sort));
    final nowHour = now().hour;
    var slot = slots
        .where((s) => nowHour >= s.startHour && nowHour < s.endHour)
        .firstOrNull;
    if (slot == null && kQrIgnoresOperatingHours && slots.isNotEmpty) {
      // Demo: the next slot to open, or the last one after closing time.
      final upcoming = slots.where((s) => s.startHour > nowHour).toList()
        ..sort((a, b) => a.startHour.compareTo(b.startHour));
      slot =
          upcoming.firstOrNull ??
          slots.reduce((a, b) => a.endHour >= b.endHour ? a : b);
    }
    if (slot == null) {
      if (slots.isEmpty) {
        throw const AppException(
          'Solar Hub belum punya jam operasional. Hubungi admin koperasi.',
        );
      }
      final earliest = slots
          .map((s) => s.startHour)
          .reduce((a, b) => a < b ? a : b);
      final latest = slots
          .map((s) => s.endHour)
          .reduce((a, b) => a > b ? a : b);
      throw AppException(
        'Solar Hub hanya melayani pukul '
        '${earliest.toString().padLeft(2, '0')}.00–'
        '${latest.toString().padLeft(2, '0')}.00. '
        'Coba lagi di jam operasional.',
      );
    }

    final today = dayOf(now());
    final booking = await _createBooking(
      me: me,
      slotId: slot.id,
      date: today,
      applianceName: applianceName,
      estKwh: estKwh,
      status: BookingStatus.pendingVerification,
    );

    await notifyAdmins(
      cooperativeId: me.cooperativeId,
      type: 'hub_connection_requested',
      title: 'Permintaan verifikasi hub',
      body: '${me.fullName} minta memakai Solar Hub sekarang.',
      route: Paths.adminHubRequests,
    );

    return booking;
  }

  @override
  Future<void> respondToConnectionRequest({
    required Profile admin,
    required String bookingId,
    required bool approve,
  }) async {
    final row = db.find(Tbl.hubBookings, bookingId);
    if (row == null) throw const AppException('Permintaan tidak ditemukan.');
    final booking = HubBooking.fromRow(row);
    final hub = _hub(booking.hubId);
    requireAdmin(admin, hub.cooperativeId);
    if (booking.status != BookingStatus.pendingVerification) {
      throw const AppException('Permintaan ini sudah diproses sebelumnya.');
    }
    final status = approve ? BookingStatus.booked : BookingStatus.cancelled;
    await db.update(Tbl.hubBookings, bookingId, {'status': status.db});

    await notify(
      userId: booking.userId,
      type: approve ? 'hub_connection_approved' : 'hub_connection_rejected',
      title: approve ? 'Permintaan hub disetujui' : 'Permintaan hub ditolak',
      body: approve
          ? 'Admin menyetujui pemakaian Solar Hub Anda. Selamat memakai!'
          : 'Admin menolak permintaan pemakaian Solar Hub Anda.',
      route: Paths.memberSolar,
    );
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
    if (booking.status == BookingStatus.pendingVerification) {
      // The owner may withdraw her own pending request, but only an admin
      // can approve it into a real booking.
      if (status == BookingStatus.booked && !isAdmin) {
        throw const AppException(
          'Hanya admin yang bisa memverifikasi permintaan ini.',
        );
      }
      if (status != BookingStatus.booked && status != BookingStatus.cancelled) {
        throw const AppException(
          'Status tidak valid untuk permintaan yang menunggu verifikasi.',
        );
      }
    } else if (booking.status != BookingStatus.booked) {
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

  @override
  Future<Profile> setMemberHubAllocation({
    required Profile admin,
    required String memberId,
    double? allocationKwh,
  }) async {
    final member = profileById(memberId);
    requireAdmin(admin, member.cooperativeId);
    if (allocationKwh != null &&
        (allocationKwh < 0 || allocationKwh > 100000)) {
      throw const AppException('Alokasi kapasitas tidak masuk akal.');
    }
    await db.update(Tbl.profiles, memberId, {
      'hub_allocation_kwh': allocationKwh,
    });
    return profileById(memberId);
  }
}
