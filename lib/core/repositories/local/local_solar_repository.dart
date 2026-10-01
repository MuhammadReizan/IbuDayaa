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
    if (row == null) {
      throw const AppException(
        'Solar Hub tidak ditemukan.',
        en: 'Solar Hub not found.',
      );
    }
    return SolarHub.fromRow(row);
  }

  SolarHub _hubOfCooperative(String cooperativeId) {
    final row = db.first(
      Tbl.solarHubs,
      (r) => r['cooperative_id'] == cooperativeId,
    );
    if (row == null) {
      throw const AppException(
        'Solar Hub tidak ditemukan.',
        en: 'Solar Hub not found.',
      );
    }
    return SolarHub.fromRow(row);
  }

  @override
  Future<SolarHub> updateHub(Profile admin, SolarHub hub) async {
    final current = _hub(hub.id);
    requireAdmin(admin, current.cooperativeId);
    if (hub.name.trim().isEmpty) {
      throw const AppException(
        'Nama hub wajib diisi.',
        en: 'Enter the hub name.',
      );
    }
    if (hub.dailyCapacityKwh < 0 || hub.dailyCapacityKwh > 100000) {
      throw const AppException(
        'Kapasitas harian tidak masuk akal.',
        en: 'The daily capacity isn\'t realistic.',
      );
    }
    if (hub.maxLoadKw < 0 || hub.maxLoadKw > 1000) {
      throw const AppException(
        'Batas daya inverter tidak masuk akal.',
        en: 'The inverter power limit isn\'t realistic.',
      );
    }
    if (hub.maxMembersPerSlot < 0 || hub.maxMembersPerSlot > 100) {
      throw const AppException(
        'Jumlah anggota per slot harus antara 0 dan 100 (0 = tanpa batas).',
        en: 'Members per slot must be between 0 and 100 (0 = no limit).',
      );
    }
    await db.update(Tbl.solarHubs, hub.id, {
      'name': hub.name.trim(),
      'location': hub.location.trim(),
      'daily_capacity_kwh': hub.dailyCapacityKwh,
      'max_load_kw': hub.maxLoadKw,
      'max_members_per_slot': hub.maxMembersPerSlot,
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
    if (startHour < 6 || endHour > 18 || endHour <= startHour) {
      // Slots stay within the daylight hours the hub is open for;
      // the weather window and the capacity figure are daytime figures.
      throw const AppException(
        'Jam slot harus di antara 06.00 dan 18.00.',
        en: 'Slot hours must be between 06.00 and 18.00.',
      );
    }
    final slots = db
        .select(Tbl.hubSlots, (r) => r['hub_id'] == hubId)
        .map(HubSlot.fromRow)
        .toList();
    final overlaps = slots.any(
      (s) => startHour < s.endHour && endHour > s.startHour,
    );
    if (overlaps) {
      throw const AppException(
        'Slot ini bertabrakan dengan slot lain.',
        en: 'This slot overlaps another slot.',
      );
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
    if (row == null) {
      throw const AppException('Slot tidak ditemukan.', en: 'Slot not found.');
    }
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
        en: 'This slot still has bookings. Cancel them or wait until they are done.',
      );
    }
    await db.delete(Tbl.hubSlots, slotId);
  }

  @override
  Future<void> setSlotOpen(Profile admin, String slotId, bool open) async {
    final row = db.find(Tbl.hubSlots, slotId);
    if (row == null) {
      throw const AppException('Slot tidak ditemukan.', en: 'Slot not found.');
    }
    requireAdmin(admin, _hub(HubSlot.fromRow(row).hubId).cooperativeId);
    await db.update(Tbl.hubSlots, slotId, {'is_open': open});
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
    double loadKw = 0,
    DateTime? requestedAt,
    bool enforceLimits = true,
  }) async {
    final slotRow = db.find(Tbl.hubSlots, slotId);
    if (slotRow == null) {
      throw const AppException('Slot tidak ditemukan.', en: 'Slot not found.');
    }
    final slot = HubSlot.fromRow(slotRow);
    final hub = _hub(slot.hubId);
    if (hub.cooperativeId != me.cooperativeId) {
      throw const AppException(
        'Slot ini bukan milik koperasi Anda.',
        en: 'This slot doesn\'t belong to your cooperative.',
      );
    }
    if (!hub.isConfigured) {
      throw const AppException(
        'Kapasitas Solar Hub belum diatur admin. Booking belum bisa dibuka.',
        en: 'The admin hasn\'t set the Solar Hub capacity yet. Booking isn\'t open.',
      );
    }
    if (estKwh <= 0) {
      throw const AppException(
        'Pilih alat yang akan dipakai.',
        en: 'Choose the appliance to use.',
      );
    }
    if (loadKw < 0) {
      throw const AppException(
        'Daya alat tidak valid.',
        en: 'Invalid appliance power.',
      );
    }
    if (enforceLimits && !slot.isOpen) {
      throw AppException(
        'Slot ${slot.label} ditutup admin sementara. Pilih slot lain.',
        en: 'Slot ${slot.label} is temporarily closed by the admin. Choose another slot.',
      );
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
      date: date,
    ).firstWhere((a) => a.slot.id == slotId);
    // One member, one seat: more appliances go into the same booking.
    final alreadyHere = bookings.any(
      (b) =>
          b.userId == me.id &&
          b.slotId == slotId &&
          b.countsAgainstCapacity &&
          sameDay(b.bookingDate, date),
    );
    if (alreadyHere) {
      throw AppException(
        'Anda sudah punya booking di slot ${slot.label} pada hari itu. '
        'Batalkan dulu atau pilih slot lain.',
        en: 'You already have a booking in slot ${slot.label} that day. Cancel it first or choose another slot.',
      );
    }
    if (enforceLimits && !availability.hasSeat) {
      throw AppException(
        'Slot ${slot.label} sudah penuh '
        '(${availability.bookedMembers} dari ${availability.seatLimit} '
        'anggota). Pilih slot lain.',
        en: 'Slot ${slot.label} is full (${availability.bookedMembers} of ${availability.seatLimit} members). Choose another slot.',
      );
    }
    if (enforceLimits && !availability.fitsKwh(estKwh)) {
      throw AppException(
        'Energi hub hari itu tinggal '
        '${kwhId(availability.dayRemainingKwh)} kWh dari '
        '${kwhId(availability.dayCapacityKwh)} kWh. '
        'Pilih alat yang lebih sedikit atau hari lain.',
        en: 'The hub only has ${availability.dayRemainingKwh.toStringAsFixed(1)} kWh of ${availability.dayCapacityKwh.toStringAsFixed(1)} kWh left that day. Choose fewer appliances or another day.',
      );
    }
    if (enforceLimits && !availability.fitsLoad(loadKw)) {
      throw AppException(
        'Beban serentak slot ${slot.label} akan menjadi '
        '${kwhId(availability.loadKw + loadKw)} kW, melebihi '
        'batas inverter hub ${kwhId(availability.maxLoadKw)} kW. '
        'Pilih slot lain.',
        en: 'The simultaneous load of slot ${slot.label} would become ${(availability.loadKw + loadKw).toStringAsFixed(1)} kW, above the hub inverter limit of ${availability.maxLoadKw.toStringAsFixed(1)} kW. Choose another slot.',
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
    if (enforceLimits && balance.availableKwh + 1e-9 < estKwh) {
      throw AppException(
        'Kuota energi Anda bulan ini tinggal '
        '${kwhId(balance.availableKwh)} kWh. Minta kuota ke '
        'anggota lain di menu Tukar Kuota.',
        en: 'Your energy quota this month is down to ${balance.availableKwh.toStringAsFixed(1)} kWh. Ask other members for quota in Quota Swap.',
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
      loadKw: loadKw,
      requestedAt: requestedAt,
    );
    await db.insert(Tbl.hubBookings, booking.toRow());
    return booking;
  }

  /// After closing time: no booking for today and no scan, and she is told it is
  /// the working hours, not something she did wrong.
  AppException _closedForTheDay({required bool scan}) => AppException(
    scan
        ? 'Sudah lewat jam kerja Solar Hub ($hubHoursLabel), jadi scan QR tidak '
              'bisa lagi hari ini. Booking dan scan bisa dilakukan lagi besok.'
        : 'Sudah lewat jam kerja Solar Hub ($hubHoursLabel), jadi booking untuk '
              'hari ini tidak bisa lagi. Pilih tanggal besok atau sesudahnya.',
    en: scan
        ? 'The Solar Hub is closed for the day (working hours $hubHoursLabel), so '
              'QR scans are no longer possible today. Booking and scanning open '
              'again tomorrow.'
        : 'The Solar Hub is closed for the day (working hours $hubHoursLabel), so '
              'booking for today is no longer possible. Choose tomorrow or later.',
  );

  /// Before opening time: a scan has nothing to attach to yet.
  AppException _notOpenYet() => AppException(
    'Solar Hub belum buka. Jam kerja $hubHoursLabel; scan QR bisa dilakukan '
    'mulai pukul ${kHubOpensHour.toString().padLeft(2, "0")}.00.',
    en:
        'The Solar Hub isn\x27t open yet. Working hours are $hubHoursLabel; you can '
        'scan from ${kHubOpensHour.toString().padLeft(2, "0")}.00.',
  );

  @override
  Future<HubBooking> book({
    required Profile me,
    required String slotId,
    required DateTime date,
    required String applianceName,
    required double estKwh,
    double loadKw = 0,
  }) async {
    requireMember(me);
    final slotRow = db.find(Tbl.hubSlots, slotId);
    if (slotRow == null) {
      throw const AppException('Slot tidak ditemukan.', en: 'Slot not found.');
    }
    final slot = HubSlot.fromRow(slotRow);

    if (sameDay(dayOf(date), dayOf(now())) && now().hour >= kHubClosesHour) {
      throw _closedForTheDay(scan: false);
    }
    final today = dayOf(now());
    final day = dayOf(date);
    if (day.isBefore(today) ||
        day.isAfter(today.add(const Duration(days: bookingWindowDays)))) {
      throw const AppException(
        'Booking hanya bisa untuk hari ini sampai 14 hari ke depan.',
        en: 'You can only book from today up to 14 days ahead.',
      );
    }
    if (sameDay(day, today) && now().hour >= slot.endHour) {
      throw const AppException(
        'Slot ini sudah lewat untuk hari ini.',
        en: 'This slot has already passed for today.',
      );
    }

    return _createBooking(
      me: me,
      slotId: slotId,
      date: day,
      applianceName: applianceName,
      estKwh: estKwh,
      status: BookingStatus.booked,
      loadKw: loadKw,
    );
  }

  @override
  Future<HubBooking> requestConnection({
    required Profile me,
    required String scannedCode,
    required String applianceName,
    required double estKwh,
    double loadKw = 0,
  }) async {
    requireMember(me);
    final hub = _hubOfCooperative(me.cooperativeId);
    if (scannedCode.trim().toUpperCase() != kSolarHubQr.toUpperCase()) {
      throw const AppException(
        'QR ini bukan QR Solar Hub koperasi Anda.',
        en: 'This QR isn\'t your cooperative\'s Solar Hub QR.',
      );
    }

    // Hours come before the booking rule: after closing there is nothing left
    // to book, so "book first" would be the wrong thing to tell her.
    if (!kQrIgnoresOperatingHours) {
      final hour = now().hour;
      if (hour >= kHubClosesHour) throw _closedForTheDay(scan: true);
      if (hour < kHubOpensHour) throw _notOpenYet();
    }

    final slots =
        db
            .select(Tbl.hubSlots, (r) => r['hub_id'] == hub.id)
            .map(HubSlot.fromRow)
            .toList()
          ..sort((a, b) => a.sort.compareTo(b.sort));
    final nowHour = now().hour;

    if (kQrRequiresBooking) {
      // Arriving is the scan: it attaches to a slot she booked for today,
      // preferring the one running now, else the next one she booked.
      final today = dayOf(now());
      final mine = db
          .select(
            Tbl.hubBookings,
            (r) =>
                r['user_id'] == me.id &&
                r['hub_id'] == hub.id &&
                r['status'] == 'booked' &&
                sameDay(rDate(r, 'booking_date'), today),
          )
          .map(HubBooking.fromRow)
          .toList();
      HubSlot? slotOf(HubBooking b) =>
          slots.where((s) => s.id == b.slotId).firstOrNull;
      mine.sort(
        (a, b) => (slotOf(a)?.sort ?? 0).compareTo(slotOf(b)?.sort ?? 0),
      );
      final running = mine.where((b) {
        final s = slotOf(b);
        return s != null && nowHour >= s.startHour && nowHour < s.endHour;
      });
      final booked = running.firstOrNull ?? mine.firstOrNull;
      if (booked == null) {
        throw const AppException(
          'Booking slot dulu sebelum scan QR. Buka menu Booking, pilih slot '
          'jam Anda, lalu scan saat tiba di Solar Hub.',
          en: 'Book a slot first before scanning the QR. Open Booking, pick your time slot, then scan when you arrive at the Solar Hub.',
        );
      }
      await db.update(Tbl.hubBookings, booked.id, {
        'status': BookingStatus.pendingVerification.db,
        'requested_at': ts(now()),
      });
      await notifyAdmins(
        cooperativeId: me.cooperativeId,
        type: 'hub_connection_requested',
        title: 'Permintaan verifikasi hub',
        titleEn: 'Hub verification request',
        bodyEn:
            '${me.fullName} arrived for the booked slot '
            '(${slotOf(booked)?.label ?? 'today'}).',
        body:
            '${me.fullName} tiba untuk slot yang sudah dipesan '
            '(${slotOf(booked)?.label ?? 'hari ini'}).',
        route: Paths.adminHubRequests,
      );
      return HubBooking.fromRow(db.find(Tbl.hubBookings, booked.id)!);
    }

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
          en: 'The Solar Hub has no operating hours yet. Contact the cooperative admin.',
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
        '${earliest.toString().padLeft(2, "0")}.00–'
        '${latest.toString().padLeft(2, "0")}.00. '
        'Coba lagi di jam operasional.',
        en: 'The Solar Hub only operates from ${earliest.toString().padLeft(2, "0")}.00 to ${latest.toString().padLeft(2, "0")}.00. Try again during operating hours.',
      );
    }

    if (!kQrIgnoresHubLimits && !slot.isOpen) {
      throw AppException(
        'Slot ${slot.label} ditutup admin sementara. Hubungi admin koperasi.',
        en: 'Slot ${slot.label} is temporarily closed by the admin. Contact the cooperative admin.',
      );
    }

    final today = dayOf(now());
    // She already booked this slot: arriving is the QR scan, so attach to that
    // booking rather than reserving the same capacity twice.
    final booked = db.first(
      Tbl.hubBookings,
      (r) =>
          r['user_id'] == me.id &&
          r['slot_id'] == slot!.id &&
          r['status'] == 'booked' &&
          sameDay(rDate(r, 'booking_date'), today),
    );
    final HubBooking booking;
    if (booked != null) {
      await db.update(Tbl.hubBookings, booked['id'] as String, {
        'status': BookingStatus.pendingVerification.db,
        'requested_at': ts(now()),
      });
      booking = HubBooking.fromRow(
        db.find(Tbl.hubBookings, booked['id'] as String)!,
      );
    } else {
      booking = await _createBooking(
        me: me,
        slotId: slot.id,
        date: today,
        applianceName: applianceName,
        estKwh: estKwh,
        status: BookingStatus.pendingVerification,
        loadKw: loadKw,
        requestedAt: now(),
        enforceLimits: !kQrIgnoresHubLimits,
      );
    }

    await notifyAdmins(
      cooperativeId: me.cooperativeId,
      type: 'hub_connection_requested',
      title: 'Permintaan verifikasi hub',
      titleEn: 'Hub verification request',
      bodyEn: booked != null
          ? '${me.fullName} arrived for the booked slot (${slot.label}).'
          : '${me.fullName} wants to use the Solar Hub now.',
      body: booked != null
          ? '${me.fullName} tiba untuk slot yang sudah dipesan (${slot.label}).'
          : '${me.fullName} minta memakai Solar Hub sekarang.',
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
    if (row == null) {
      throw const AppException(
        'Permintaan tidak ditemukan.',
        en: 'Request not found.',
      );
    }
    final booking = HubBooking.fromRow(row);
    final hub = _hub(booking.hubId);
    requireAdmin(admin, hub.cooperativeId);
    if (booking.status != BookingStatus.pendingVerification) {
      throw const AppException(
        'Permintaan ini sudah diproses sebelumnya.',
        en: 'This request has already been processed.',
      );
    }
    final status = approve ? BookingStatus.booked : BookingStatus.cancelled;
    await db.update(Tbl.hubBookings, bookingId, {'status': status.db});

    // What she has left this month, after this session (it is already counted
    // while booked; a rejection gives it back).
    final left = _quotaLeft(
      booking.userId,
      booking.bookingDate,
    ).toStringAsFixed(1);
    final kwh = booking.estKwh.toStringAsFixed(1);
    final leftComma = left.replaceAll('.', ',');
    final kwhComma = kwh.replaceAll('.', ',');
    await notify(
      userId: booking.userId,
      type: approve ? 'hub_connection_approved' : 'hub_connection_rejected',
      title: approve ? 'Permintaan hub disetujui' : 'Permintaan hub ditolak',
      titleEn: approve ? 'Hub request approved' : 'Hub request rejected',
      bodyEn: approve
          ? 'The admin approved your Solar Hub use: $kwh kWh recorded. '
                '$left kWh of your quota is left this month.'
          : 'The admin rejected your Solar Hub use request. '
                '$left kWh of your quota is left this month.',
      body: approve
          ? 'Admin menyetujui pemakaian Solar Hub Anda: $kwhComma kWh tercatat. '
                'Sisa kuota bulan ini $leftComma kWh.'
          : 'Admin menolak permintaan pemakaian Solar Hub Anda. '
                'Sisa kuota bulan ini $leftComma kWh.',
      route: Paths.memberSolar,
    );
  }

  /// A member's remaining quota in the month of [date], from stored rows.
  double _quotaLeft(String userId, DateTime date) {
    final member = profileById(userId);
    final coop = cooperativeById(member.cooperativeId);
    return quotaBalance(
      userId: userId,
      month: date,
      allocationKwh: member.hubAllocationKwh ?? coop.memberMonthlyQuotaKwh,
      bookings: db
          .select(Tbl.hubBookings, (r) => r['user_id'] == userId)
          .map(HubBooking.fromRow),
      offers: db
          .select(Tbl.quotaOffers, (r) => r['cooperative_id'] == coop.id)
          .map(QuotaOffer.fromRow),
    ).availableKwh;
  }

  @override
  Future<void> setBookingStatus(
    Profile actor,
    String bookingId,
    BookingStatus status,
  ) async {
    final row = db.find(Tbl.hubBookings, bookingId);
    if (row == null) {
      throw const AppException(
        'Booking tidak ditemukan.',
        en: 'Booking not found.',
      );
    }
    final booking = HubBooking.fromRow(row);
    final hub = _hub(booking.hubId);
    final isOwner = booking.userId == actor.id;
    final isAdmin = actor.isAdmin && actor.cooperativeId == hub.cooperativeId;
    if (!isOwner && !isAdmin) {
      throw const AppException(
        'Anda tidak bisa mengubah booking ini.',
        en: 'You can\'t change this booking.',
      );
    }
    if (booking.status == BookingStatus.pendingVerification) {
      // The owner may withdraw her own pending request, but only an admin
      // can approve it into a real booking.
      if (status == BookingStatus.booked && !isAdmin) {
        throw const AppException(
          'Hanya admin yang bisa memverifikasi permintaan ini.',
          en: 'Only an admin can verify this request.',
        );
      }
      if (status != BookingStatus.booked && status != BookingStatus.cancelled) {
        throw const AppException(
          'Status tidak valid untuk permintaan yang menunggu verifikasi.',
          en: 'Invalid status for a request awaiting verification.',
        );
      }
    } else if (booking.status != BookingStatus.booked) {
      throw const AppException(
        'Booking ini sudah selesai atau dibatalkan.',
        en: 'This booking is already completed or cancelled.',
      );
    } else if (status != BookingStatus.completed &&
        status != BookingStatus.cancelled) {
      throw const AppException(
        'Status tidak valid untuk booking yang sudah diverifikasi.',
        en: 'Invalid status for a verified booking.',
      );
    }
    // Usage is recorded only by an admin, from the scan she approved or from a
    // session she confirms. A member cannot mark her own session used: that
    // would let her write her own energy history and credit score.
    if (status == BookingStatus.completed && !isAdmin) {
      throw const AppException(
        'Hanya admin yang bisa mengonfirmasi pemakaian. Scan QR Solar Hub saat tiba.',
        en: 'Only an admin can confirm usage. Scan the Solar Hub QR when you arrive.',
      );
    }
    if (status == BookingStatus.completed &&
        booking.bookingDate.isAfter(dayOf(now()))) {
      throw const AppException(
        'Pemakaian baru bisa dikonfirmasi pada atau setelah hari booking.',
        en: 'Usage can only be confirmed on or after the booking day.',
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
      throw const AppException(
        'Alokasi kapasitas tidak masuk akal.',
        en: 'The capacity allocation isn\'t realistic.',
      );
    }
    await db.update(Tbl.profiles, memberId, {
      'hub_allocation_kwh': allocationKwh,
    });
    return profileById(memberId);
  }
}
