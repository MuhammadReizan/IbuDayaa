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
    if (row == null) {
      throw const AppException(
        'Grup arisan tidak ditemukan.',
        en: 'Arisan group not found.',
      );
    }
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
      throw const AppException(
        'Nama grup wajib diisi.',
        en: 'Enter the group name.',
      );
    }
    if (contributionIdr < 1000) {
      throw const AppException(
        'Iuran minimal Rp 1.000.',
        en: 'Minimum dues are Rp 1,000.',
      );
    }
    final ids = memberIdsInTurnOrder.toSet().toList();
    if (ids.length < 2) {
      throw const AppException(
        'Grup arisan butuh minimal 2 anggota.',
        en: 'An arisan group needs at least 2 members.',
      );
    }
    for (final id in ids) {
      final p = profileById(id);
      if (p.cooperativeId != admin.cooperativeId || p.isAdmin) {
        throw AppException(
          '${p.fullName} bukan anggota koperasi ini.',
          en: '${p.fullName} is not a member of this cooperative.',
        );
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
          titleEn: 'You joined the group ${group.name}',
          bodyEn:
              'Your turn is ${i + 1} of ${ids.length}. Dues are '
              'Rp${_thousands(contributionIdr, ",")} per month.',
          route: Paths.arisan,
        );
      }
      await postSystemMessage(
        threadId,
        'Grup ${group.name} dibuat dengan ${ids.length} anggota.',
        bodyEn: 'Group ${group.name} was created with ${ids.length} members.',
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
      throw const AppException(
        'Anda bukan anggota grup ini.',
        en: 'You aren\'t a member of this group.',
      );
    }
    final month = monthOf(periodMonth);
    if (month.isBefore(group.startMonth)) {
      throw const AppException(
        'Arisan belum dimulai pada bulan itu.',
        en: 'The arisan hasn\'t started in that month.',
      );
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
        en: duplicate['status'] == 'pending'
            ? 'Your payment for this month has been sent and is waiting for admin confirmation.'
            : "This month's dues are already paid.",
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
        titleEn: 'Arisan payment awaiting confirmation',
        bodyEn:
            '${me.fullName} paid the ${group.name} dues for '
            '${monthLabelEn(month)}.',
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
    if (row == null) {
      throw const AppException(
        'Setoran tidak ditemukan.',
        en: 'Payment not found.',
      );
    }
    final payment = ArisanPayment.fromRow(row);
    final group = _group(payment.groupId);
    requireAdmin(admin, group.cooperativeId);
    if (payment.status != PaymentStatus.pending) {
      throw const AppException(
        'Setoran ini sudah diproses.',
        en: 'This payment has already been processed.',
      );
    }
    if (!approve && (note == null || note.trim().isEmpty)) {
      throw const AppException(
        'Tulis alasan penolakan agar anggota paham.',
        en: 'Write the reason for rejecting so the member understands.',
      );
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
        titleEn: approve ? 'Dues confirmed' : 'Payment rejected',
        bodyEn: approve
            ? '${group.name} dues for ${monthLabelEn(payment.periodMonth)} '
                  'are recorded as paid.'
            : '${group.name} payment rejected: ${note!.trim()}',
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
      throw const AppException(
        'Penerima bukan anggota grup ini.',
        en: 'The recipient isn\'t a member of this group.',
      );
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
      throw const AppException(
        'Pencairan untuk bulan ini sudah dicatat.',
        en: 'This month\'s payout has already been recorded.',
      );
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
        titleEn: 'Your arisan turn has been paid out',
        bodyEn:
            'Rp${_thousands(payout.amountIdr, ",")} from ${group.name} for '
            '${monthLabelEn(month)}.',
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
        '${kwhId(available)} kWh.',
        en: '${giver.fullName}\'s quota this month is down to ${available.toStringAsFixed(1)} kWh.',
      );
    }
  }

  QuotaOffer _offer(String id) {
    final row = db.find(Tbl.quotaOffers, id);
    if (row == null) {
      throw const AppException(
        'Penawaran tidak ditemukan.',
        en: 'Offer not found.',
      );
    }
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
      throw const AppException(
        'Jumlah kuota harus lebih dari 0 kWh.',
        en: 'The quota amount must be more than 0 kWh.',
      );
    }
    if (kind == QuotaKind.share) _requireAvailable(me, kwh);
    Profile? target;
    if (toMemberId != null) {
      if (kind != QuotaKind.share) {
        throw const AppException(
          'Hanya kuota yang dibagikan yang bisa dikirim ke anggota tertentu.',
          en: 'Only shared quota can be sent to a specific member.',
        );
      }
      target = profileById(toMemberId);
      if (target.cooperativeId != me.cooperativeId ||
          target.id == me.id ||
          target.isAdmin) {
        throw const AppException(
          'Anggota penerima tidak valid.',
          en: 'Invalid recipient member.',
        );
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
          body: '${kwhId(kwh)} kWh. Terima atau tolak di Tukar Kuota.',
          titleEn: '${me.fullName} is sharing quota with you',
          bodyEn:
              '${kwh.toStringAsFixed(1)} kWh. Accept or decline in Quota Swap.',
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
        en: 'This quota isn\'t for you or has already been answered.',
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
            ? '${kwhId(offer.kwh)} kWh sudah tercatat.'
            : '${kwhId(offer.kwh)} kWh tidak jadi berpindah.',
        titleEn: accept
            ? '${me.fullName} accepted your quota'
            : '${me.fullName} declined your quota',
        bodyEn: accept
            ? '${offer.kwh.toStringAsFixed(1)} kWh has been recorded.'
            : '${offer.kwh.toStringAsFixed(1)} kWh will not be transferred.',
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
      throw const AppException(
        'Penawaran ini bukan dari koperasi Anda.',
        en: 'This offer isn\'t from your cooperative.',
      );
    }
    if (offer.ownerId == me.id) {
      throw const AppException(
        'Ini penawaran Anda sendiri.',
        en: 'This is your own offer.',
      );
    }
    if (offer.status != QuotaStatus.open) {
      throw const AppException(
        'Penawaran ini sudah ditanggapi anggota lain.',
        en: 'Another member has already responded to this offer.',
      );
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
            '${kwhId(offer.kwh)} kWh. '
            'Sudah tercatat di Tukar Kuota.',
        titleEn: offer.kind == QuotaKind.share
            ? '${me.fullName} accepted your quota'
            : '${me.fullName} gave you quota',
        bodyEn:
            '${offer.kwh.toStringAsFixed(1)} kWh. '
            'Already recorded in Quota Swap.',
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
        en: 'Only the offer creator can cancel it.',
      );
    }
    if (offer.status == QuotaStatus.completed ||
        offer.status == QuotaStatus.cancelled) {
      throw const AppException(
        'Penawaran ini sudah selesai.',
        en: 'This offer is already completed.',
      );
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
              '${kwhId(offer.kwh)} kWh.',
          titleEn: 'Quota offer cancelled',
          bodyEn:
              '${me.fullName} cancelled the '
              '${offer.kwh.toStringAsFixed(1)} kWh offer.',
          route: Paths.quota,
        );
      }
    });
  }
}

String _thousands(int v, [String sep = '.']) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(sep);
    b.write(s[i]);
  }
  return b.toString();
}
