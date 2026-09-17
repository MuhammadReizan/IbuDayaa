import '../../db/ids.dart';
import '../../db/row.dart';
import '../../db/tables.dart';
import '../../errors.dart';
import '../../models/models.dart';
import '../../paths.dart';
import '../repositories.dart';
import 'local_base.dart';

class LocalMessageRepository extends LocalRepo
    implements MessageRepository, CooperativeRepository {
  LocalMessageRepository(super.db, super.now);

  MessageThread _thread(String id) {
    final row = db.find(Tbl.messageThreads, id);
    if (row == null) throw const AppException('Percakapan tidak ditemukan.');
    return MessageThread.fromRow(row);
  }

  bool _isParticipant(String threadId, String userId) =>
      db.first(
        Tbl.threadParticipants,
        (r) => r['thread_id'] == threadId && r['user_id'] == userId,
      ) !=
      null;

  @override
  Future<MessageThread> directThread({
    required Profile me,
    required String otherUserId,
  }) async {
    final other = profileById(otherUserId);
    if (other.cooperativeId != me.cooperativeId) {
      throw const AppException('Anggota ini bukan dari koperasi Anda.');
    }
    if (other.id == me.id) {
      throw const AppException('Tidak bisa mengirim pesan ke diri sendiri.');
    }

    final mine = db
        .select(Tbl.threadParticipants, (r) => r['user_id'] == me.id)
        .map((r) => r['thread_id'])
        .toSet();
    final existing = db.first(
      Tbl.messageThreads,
      (r) =>
          r['kind'] == 'direct' &&
          mine.contains(r['id']) &&
          _isParticipant(r['id'] as String, other.id),
    );
    if (existing != null) return MessageThread.fromRow(existing);

    return db.transaction(() async {
      final thread = MessageThread(
        id: newId(),
        cooperativeId: me.cooperativeId,
        kind: ThreadKind.direct,
        title: '',
        createdAt: now(),
      );
      await db.insert(Tbl.messageThreads, thread.toRow());
      await addParticipant(thread.id, me.id);
      await addParticipant(thread.id, other.id);
      return thread;
    });
  }

  @override
  Future<Message> send({
    required Profile me,
    required String threadId,
    required String body,
  }) async {
    final text = body.trim();
    if (text.isEmpty) throw const AppException('Pesan masih kosong.');
    if (text.length > 2000) {
      throw const AppException('Pesan terlalu panjang (maks. 2.000 huruf).');
    }
    final thread = _thread(threadId);
    if (!_isParticipant(threadId, me.id)) {
      throw const AppException('Anda tidak ada di percakapan ini.');
    }
    if (thread.kind == ThreadKind.announcement && !me.isAdmin) {
      throw const AppException('Hanya admin yang bisa menulis pengumuman.');
    }

    return db.transaction(() async {
      final msg = Message(
        id: newId(),
        threadId: threadId,
        senderId: me.id,
        body: text,
        createdAt: now(),
      );
      await db.insert(Tbl.messages, msg.toRow());
      await _touchRead(threadId, me.id);

      if (thread.kind == ThreadKind.announcement) {
        final readers = db
            .select(Tbl.threadParticipants, (r) => r['thread_id'] == threadId)
            .map((r) => r['user_id'] as String)
            .where((id) => id != me.id);
        for (final id in readers) {
          await notify(
            userId: id,
            type: 'announcement',
            title: 'Pengumuman koperasi',
            body: text.length > 120 ? '${text.substring(0, 117)}...' : text,
            route: Paths.thread(threadId),
          );
        }
      }
      return msg;
    });
  }

  Future<void> _touchRead(String threadId, String userId) async {
    final p = db.first(
      Tbl.threadParticipants,
      (r) => r['thread_id'] == threadId && r['user_id'] == userId,
    );
    if (p != null) {
      await db.update(Tbl.threadParticipants, p['id'] as String, {
        'last_read_at': ts(now()),
      });
    }
  }

  @override
  Future<void> markThreadRead({
    required Profile me,
    required String threadId,
  }) => _touchRead(threadId, me.id);

  @override
  Future<void> markNotificationRead(Profile me, String notificationId) async {
    final row = db.find(Tbl.notifications, notificationId);
    if (row == null || row['user_id'] != me.id || row['read_at'] != null) {
      return;
    }
    await db.update(Tbl.notifications, notificationId, {'read_at': ts(now())});
  }

  @override
  Future<void> markAllNotificationsRead(Profile me) async {
    final unread = db.select(
      Tbl.notifications,
      (r) => r['user_id'] == me.id && r['read_at'] == null,
    );
    if (unread.isEmpty) return;
    await db.transaction(() async {
      for (final r in unread) {
        await db.update(Tbl.notifications, r['id'] as String, {
          'read_at': ts(now()),
        });
      }
    });
  }

  // -- Cooperative settings -------------------------------------------------

  @override
  Future<Cooperative> updateSettings(Profile admin, Cooperative updated) async {
    requireAdmin(admin, updated.id);
    if (updated.name.trim().isEmpty) {
      throw const AppException('Nama koperasi wajib diisi.');
    }
    if (updated.loanFlatMonthlyRatePct < 0 ||
        updated.loanFlatMonthlyRatePct > 10) {
      throw const AppException('Bunga per bulan harus antara 0% dan 10%.');
    }
    if (updated.loanMaxAmountIdr < 500000) {
      throw const AppException('Plafon maksimum minimal Rp 500.000.');
    }
    if (updated.loanMinScore < 0 || updated.loanMinScore > 100) {
      throw const AppException('Skor minimum harus 0 sampai 100.');
    }
    if (updated.loanTenors.isEmpty ||
        updated.loanTenors.any((t) => t < 1 || t > 36)) {
      throw const AppException('Pilih minimal satu tenor antara 1–36 bulan.');
    }
    if (updated.memberMonthlyQuotaKwh < 0) {
      throw const AppException('Kuota anggota tidak boleh negatif.');
    }
    await db.update(Tbl.cooperatives, updated.id, {
      'name': updated.name.trim(),
      'city': updated.city.trim(),
      'loan_flat_monthly_rate_pct': updated.loanFlatMonthlyRatePct,
      'loan_max_amount_idr': updated.loanMaxAmountIdr,
      'loan_min_score': updated.loanMinScore,
      'loan_tenors': ([...updated.loanTenors]..sort()),
      'member_monthly_quota_kwh': updated.memberMonthlyQuotaKwh,
      'solar_cost_per_kwp_idr': updated.solarCostPerKwpIdr,
      'arisan_bank_account': updated.arisanBankAccount?.trim().isEmpty ?? true
          ? null
          : updated.arisanBankAccount!.trim(),
    });
    return cooperativeById(updated.id);
  }

  @override
  Future<Cooperative> regenerateInviteCode(Profile admin) async {
    requireAdmin(admin, admin.cooperativeId);
    String code;
    do {
      code = newInviteCode();
    } while (db.first(Tbl.cooperatives, (r) => r['invite_code'] == code) !=
        null);
    await db.update(Tbl.cooperatives, admin.cooperativeId, {
      'invite_code': code,
    });
    return cooperativeById(admin.cooperativeId);
  }
}
