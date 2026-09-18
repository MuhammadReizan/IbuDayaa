import '../../db/ids.dart';
import '../../db/row.dart';
import '../../db/tables.dart';
import '../../errors.dart';
import '../../logic/quota_ledger.dart';
import '../../models/models.dart';
import '../../paths.dart';
import '../repositories.dart';
import 'local_base.dart';

class LocalArisanRepository extends LocalRepo implements ArisanRepository {
  LocalArisanRepository(super.db, super.now);

  ArisanGroup _group(String id) {
    final row = db.find(Tbl.arisanGroups, id);
    if (row == null) throw const AppException('Grup arisan tidak ditemukan.');
    return ArisanGroup.fromRow(row);
  }

  List<ArisanMember> _membersOf(String groupId) =>
      db
          .select(Tbl.arisanMembers, (r) => r['group_id'] == groupId)
          .map(ArisanMember.fromRow)
          .toList()
        ..sort((a, b) => a.turnOrder.compareTo(b.turnOrder));

  @override
  Future<ArisanGroup> createGroup({
    required Profile admin,
    required String name,
    required int contributionIdr,
    required DateTime startMonth,
    required List<String> memberIdsInTurnOrder,
  }) async {
    requireAdmin(admin, admin.cooperativeId);
    if (name.trim().isEmpty) {
      throw const AppException('Nama grup wajib diisi.');
    }
    if (contributionIdr < 1000) {
      throw const AppException('Iuran minimal Rp 1.000.');
    }
    final ids = memberIdsInTurnOrder.toSet().toList();
    if (ids.length < 2) {
      throw const AppException('Grup arisan butuh minimal 2 anggota.');
    }
    for (final id in ids) {
      final p = profileById(id);
      if (p.cooperativeId != admin.cooperativeId || p.isAdmin) {
        throw AppException('${p.fullName} bukan anggota koperasi ini.');
      }
    }

    return db.transaction(() async {
      final t = now();
      final group = ArisanGroup(
        id: newId(),
        cooperativeId: admin.cooperativeId,
        name: name.trim(),
        contributionIdr: contributionIdr,
        startMonth: monthOf(startMonth),
        createdBy: admin.id,
        createdAt: t,
      );
      await db.insert(Tbl.arisanGroups, group.toRow());

      final threadId = newId();
      await db.insert(
        Tbl.messageThreads,
        MessageThread(
          id: threadId,
          cooperativeId: admin.cooperativeId,
          kind: ThreadKind.group,
          title: group.name,
          refId: group.id,
          createdAt: t,
        ).toRow(),
      );
      await addParticipant(threadId, admin.id);

      for (int i = 0; i < ids.length; i++) {
        await db.insert(
          Tbl.arisanMembers,
          ArisanMember(
            id: newId(),
            groupId: group.id,
            userId: ids[i],
            turnOrder: i + 1,
            joinedAt: t,
          ).toRow(),
        );
        await addParticipant(threadId, ids[i]);
        await notify(
          userId: ids[i],
          type: 'arisan',
          title: 'Anda masuk grup ${group.name}',
          body:
              'Giliran Anda ke-${i + 1} dari ${ids.length}. Iuran '
              'Rp${_thousands(contributionIdr)} per bulan.',
          route: Paths.arisan,
        );
      }
      await postSystemMessage(
        threadId,
        'Grup ${group.name} dibuat dengan ${ids.length} anggota.',
      );
      return group;
    });
  }

  @override
  Future<ArisanPayment> submitContribution({
    required Profile me,
    required String groupId,
    required DateTime periodMonth,
    String? note,
  }) async {
    final group = _group(groupId);
    if (!_membersOf(groupId).any((m) => m.userId == me.id)) {
      throw const AppException('Anda bukan anggota grup ini.');
    }
    final month = monthOf(periodMonth);
    if (month.isBefore(group.startMonth)) {
      throw const AppException('Arisan belum dimulai pada bulan itu.');
    }
    final duplicate = db.first(
      Tbl.arisanPayments,
      (r) =>
          r['group_id'] == groupId &&
          r['user_id'] == me.id &&
          r['type'] == 'contribution' &&
          r['period_month'] == dateOnly(month) &&
          r['status'] != 'rejected',
    );
    if (duplicate != null) {
      throw AppException(
        duplicate['status'] == 'pending'
            ? 'Setoran bulan ini sudah dikirim dan menunggu konfirmasi admin.'
            : 'Iuran bulan ini sudah lunas.',
      );
    }

    return db.transaction(() async {
      final payment = ArisanPayment(
        id: newId(),
        groupId: groupId,
        userId: me.id,
        type: PaymentType.contribution,
        amountIdr: group.contributionIdr,
        periodMonth: month,
        status: PaymentStatus.pending,
        note: (note == null || note.trim().isEmpty) ? null : note.trim(),
        createdAt: now(),
      );
      await db.insert(Tbl.arisanPayments, payment.toRow());
      await notifyAdmins(
        cooperativeId: group.cooperativeId,
        type: 'payment',
        title: 'Setoran arisan menunggu konfirmasi',
        body:
            '${me.fullName} menyetor iuran ${group.name} '
            '${monthLabel(month)}.',
        route: Paths.adminPayments,
      );
      return payment;
    });
  }

  @override
  Future<void> reviewPayment({
    required Profile admin,
    required String paymentId,
    required bool approve,
    String? note,
  }) async {
    final row = db.find(Tbl.arisanPayments, paymentId);
    if (row == null) throw const AppException('Setoran tidak ditemukan.');
    final payment = ArisanPayment.fromRow(row);
    final group = _group(payment.groupId);
    requireAdmin(admin, group.cooperativeId);
    if (payment.status != PaymentStatus.pending) {
      throw const AppException('Setoran ini sudah diproses.');
    }
    if (!approve && (note == null || note.trim().isEmpty)) {
      throw const AppException('Tulis alasan penolakan agar anggota paham.');
    }

    await db.transaction(() async {
      await db.update(Tbl.arisanPayments, paymentId, {
        'status': approve ? 'confirmed' : 'rejected',
        'reviewed_by': admin.id,
        'reviewed_at': ts(now()),
        'note': note?.trim().isEmpty ?? true ? payment.note : note!.trim(),
      });
      await notify(
        userId: payment.userId,
        type: 'payment',
        title: approve ? 'Iuran terkonfirmasi' : 'Setoran ditolak',
        body: approve
            ? 'Iuran ${group.name} ${monthLabel(payment.periodMonth)} sudah '
                  'dicatat lunas.'
            : 'Setoran ${group.name} ditolak: ${note!.trim()}',
        route: Paths.arisan,
      );
    });
  }

  @override
  Future<ArisanPayment> recordPayout({
    required Profile admin,
    required String groupId,
    required String userId,
    required DateTime periodMonth,
  }) async {
    final group = _group(groupId);
    requireAdmin(admin, group.cooperativeId);
    final members = _membersOf(groupId);
    if (!members.any((m) => m.userId == userId)) {
      throw const AppException('Penerima bukan anggota grup ini.');
    }
    final month = monthOf(periodMonth);
    final already = db.first(
      Tbl.arisanPayments,
      (r) =>
          r['group_id'] == groupId &&
          r['type'] == 'payout' &&
          r['period_month'] == dateOnly(month),
    );
    if (already != null) {
      throw const AppException('Pencairan untuk bulan ini sudah dicatat.');
    }

    return db.transaction(() async {
      final payout = ArisanPayment(
        id: newId(),
        groupId: groupId,
        userId: userId,
        type: PaymentType.payout,
        amountIdr: group.contributionIdr * members.length,
        periodMonth: month,
        status: PaymentStatus.confirmed,
        reviewedBy: admin.id,
        reviewedAt: now(),
        createdAt: now(),
      );
      await db.insert(Tbl.arisanPayments, payout.toRow());
      await notify(
        userId: userId,
        type: 'payment',
        title: 'Giliran arisan Anda dicairkan',
        body:
            'Rp${_thousands(payout.amountIdr)} dari ${group.name} untuk '
            '${monthLabel(month)}.',
        route: Paths.arisan,
      );
      return payout;
    });
  }

  // -- Quota ----------------------------------------------------------------

  QuotaBalance _balance(Profile p, DateTime month) {
    final coop = cooperativeById(p.cooperativeId);
    final hubIds = db
        .select(Tbl.solarHubs, (r) => r['cooperative_id'] == coop.id)
        .map((r) => r['id'])
        .toSet();
    return quotaBalance(
      userId: p.id,
      month: month,
      allocationKwh: coop.memberMonthlyQuotaKwh,
      bookings: db
          .select(Tbl.hubBookings, (r) => hubIds.contains(r['hub_id']))
          .map(HubBooking.fromRow),
      offers: db
          .select(Tbl.quotaOffers, (r) => r['cooperative_id'] == coop.id)
          .map(QuotaOffer.fromRow),
    );
  }

  void _requireAvailable(Profile giver, double kwh) {
    final available = _balance(giver, now()).availableKwh;
    if (available + 1e-9 < kwh) {
      throw AppException(
        'Kuota ${giver.fullName} bulan ini tinggal '
        '${available.toStringAsFixed(1)} kWh.',
      );
    }
  }

  QuotaOffer _offer(String id) {
    final row = db.find(Tbl.quotaOffers, id);
    if (row == null) throw const AppException('Penawaran tidak ditemukan.');
    return QuotaOffer.fromRow(row);
  }

  @override
  Future<QuotaOffer> postQuota({
    required Profile me,
    required QuotaKind kind,
    required double kwh,
    String? note,
    String? toMemberId,
  }) async {
    requireMember(me);
    if (kwh <= 0 || kwh > 1000) {
      throw const AppException('Jumlah kuota harus lebih dari 0 kWh.');
    }
    if (kind == QuotaKind.share) _requireAvailable(me, kwh);
    Profile? target;
    if (toMemberId != null) {
      if (kind != QuotaKind.share) {
        throw const AppException(
          'Hanya kuota yang dibagikan yang bisa dikirim ke anggota tertentu.',
        );
      }
      target = profileById(toMemberId);
      if (target.cooperativeId != me.cooperativeId ||
          target.id == me.id ||
          target.isAdmin) {
        throw const AppException('Anggota penerima tidak valid.');
      }
    }
    final t = now();
    final offer = QuotaOffer(
      id: newId(),
      cooperativeId: me.cooperativeId,
      ownerId: me.id,
      kind: kind,
      kwh: kwh,
      slotNote: '',
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      status: target == null ? QuotaStatus.open : QuotaStatus.pending,
      counterpartyId: target?.id,
      createdAt: t,
      updatedAt: t,
    );
    await db.transaction(() async {
      await db.insert(Tbl.quotaOffers, offer.toRow());
      if (target != null) {
        await notify(
          userId: target.id,
          type: 'quota',
          title: '${me.fullName} membagikan kuota untuk Anda',
          body:
              '${kwh.toStringAsFixed(1)} kWh. Terima atau tolak di Tukar Kuota.',
          route: Paths.quota,
        );
      }
    });
    return offer;
  }

  @override
  Future<void> answerQuotaGift({
    required Profile me,
    required String offerId,
    required bool accept,
  }) async {
    final offer = _offer(offerId);
    if (offer.kind != QuotaKind.share ||
        offer.status != QuotaStatus.pending ||
        offer.counterpartyId != me.id) {
      throw const AppException(
        'Kuota ini bukan untuk Anda atau sudah dijawab.',
      );
    }
    final owner = profileById(offer.ownerId);
    // The sender's balance may have changed since she sent it.
    if (accept) _requireAvailable(owner, offer.kwh);

    await db.transaction(() async {
      await db.update(Tbl.quotaOffers, offerId, {
        'status': accept ? 'completed' : 'cancelled',
        'updated_at': ts(now()),
      });
      await notify(
        userId: owner.id,
        type: 'quota',
        title: accept
            ? '${me.fullName} menerima kuota Anda'
            : '${me.fullName} menolak kuota Anda',
        body: accept
            ? '${offer.kwh.toStringAsFixed(1)} kWh sudah tercatat.'
            : '${offer.kwh.toStringAsFixed(1)} kWh tidak jadi berpindah.',
        route: Paths.quota,
      );
    });
  }

  @override
  Future<void> respondToQuota({
    required Profile me,
    required String offerId,
  }) async {
    requireMember(me);
    final offer = _offer(offerId);
    if (offer.cooperativeId != me.cooperativeId) {
      throw const AppException('Penawaran ini bukan dari koperasi Anda.');
    }
    if (offer.ownerId == me.id) {
      throw const AppException('Ini penawaran Anda sendiri.');
    }
    if (offer.status != QuotaStatus.open) {
      throw const AppException('Penawaran ini sudah ditanggapi anggota lain.');
    }
    // The owner's post is her agreement and this response is the other side's,
    // so the trade completes at once — no second confirmation. The giver's
    // balance is re-checked now because it may have changed since posting.
    final owner = profileById(offer.ownerId);
    final giver = offer.kind == QuotaKind.share ? owner : me;
    _requireAvailable(giver, offer.kwh);

    await db.transaction(() async {
      await db.update(Tbl.quotaOffers, offerId, {
        'status': 'completed',
        'counterparty_id': me.id,
        'updated_at': ts(now()),
      });
      await notify(
        userId: owner.id,
        type: 'quota',
        title: offer.kind == QuotaKind.share
            ? '${me.fullName} menerima kuota Anda'
            : '${me.fullName} memberi kuota untuk Anda',
        body:
            '${offer.kwh.toStringAsFixed(1)} kWh. '
            'Sudah tercatat di Tukar Kuota.',
        route: Paths.quota,
      );
    });
  }

  @override
  Future<void> cancelQuota({
    required Profile me,
    required String offerId,
  }) async {
    final offer = _offer(offerId);
    if (offer.ownerId != me.id) {
      throw const AppException(
        'Hanya pembuat penawaran yang bisa membatalkan.',
      );
    }
    if (offer.status == QuotaStatus.completed ||
        offer.status == QuotaStatus.cancelled) {
      throw const AppException('Penawaran ini sudah selesai.');
    }
    await db.transaction(() async {
      await db.update(Tbl.quotaOffers, offerId, {
        'status': 'cancelled',
        'updated_at': ts(now()),
      });
      if (offer.counterpartyId != null) {
        await notify(
          userId: offer.counterpartyId!,
          type: 'quota',
          title: 'Penawaran kuota dibatalkan',
          body:
              '${me.fullName} membatalkan penawaran '
              '${offer.kwh.toStringAsFixed(1)} kWh.',
          route: Paths.quota,
        );
      }
    });
  }
}

String _thousands(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}
