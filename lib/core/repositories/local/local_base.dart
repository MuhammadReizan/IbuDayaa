import '../../db/ids.dart';
import '../../db/local_database.dart';
import '../../db/row.dart';
import '../../db/tables.dart';
import '../../errors.dart';
import '../../logic/credit_signals.dart';
import '../../models/models.dart';

/// Shared plumbing for local repositories: time, authorization checks, and the
/// side effects Supabase will run as database triggers (notifications, system
/// messages).
abstract class LocalRepo {
  LocalRepo(this.db, this.now);

  final LocalDatabase db;
  final DateTime Function() now;

  Profile profileById(String id) {
    final row = db.find(Tbl.profiles, id);
    if (row == null) throw const AppException('Akun tidak ditemukan.');
    return Profile.fromRow(row);
  }

  Cooperative cooperativeById(String id) {
    final row = db.find(Tbl.cooperatives, id);
    if (row == null) throw const AppException('Koperasi tidak ditemukan.');
    return Cooperative.fromRow(row);
  }

  void requireAdmin(Profile actor, String cooperativeId) {
    if (!actor.isAdmin || actor.cooperativeId != cooperativeId) {
      throw const AppException('Hanya admin koperasi yang bisa melakukan ini.');
    }
  }

  void requireMember(Profile actor) {
    if (actor.isAdmin) {
      throw const AppException('Fitur ini khusus untuk anggota koperasi.');
    }
  }

  List<Profile> adminsOf(String cooperativeId) => db
      .select(
        Tbl.profiles,
        (r) => r['cooperative_id'] == cooperativeId && r['role'] == 'admin',
      )
      .map(Profile.fromRow)
      .toList();

  Future<void> notify({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? route,
  }) => db.insert(
    Tbl.notifications,
    AppNotification(
      id: newId(),
      userId: userId,
      type: type,
      title: title,
      body: body,
      route: route,
      createdAt: now(),
    ).toRow(),
  );

  Future<void> notifyAdmins({
    required String cooperativeId,
    required String type,
    required String title,
    required String body,
    String? route,
  }) async {
    for (final a in adminsOf(cooperativeId)) {
      await notify(
        userId: a.id,
        type: type,
        title: title,
        body: body,
        route: route,
      );
    }
  }

  MessageThread? supportThreadOf(String memberId) {
    final row = db.first(
      Tbl.messageThreads,
      (r) => r['kind'] == 'support' && r['ref_id'] == memberId,
    );
    return row == null ? null : MessageThread.fromRow(row);
  }

  Future<void> postSystemMessage(String threadId, String body) => db.insert(
    Tbl.messages,
    Message(
      id: newId(),
      threadId: threadId,
      body: body,
      createdAt: now(),
    ).toRow(),
  );

  Future<void> addParticipant(String threadId, String userId) async {
    final exists = db.first(
      Tbl.threadParticipants,
      (r) => r['thread_id'] == threadId && r['user_id'] == userId,
    );
    if (exists != null) return;
    await db.insert(
      Tbl.threadParticipants,
      ThreadParticipant(
        id: newId(),
        threadId: threadId,
        userId: userId,
      ).toRow(),
    );
  }

  /// The inputs to a member's credit score, read straight from storage — the
  /// same query a Supabase function would run.
  CreditContext creditContextFor(String userId) {
    final loanIds = db
        .select(Tbl.loanApplications, (r) => r['user_id'] == userId)
        .map((r) => r['id'])
        .toSet();
    final memberships = db
        .select(Tbl.arisanMembers, (r) => r['user_id'] == userId)
        .map(ArisanMember.fromRow)
        .toList();
    final groupIds = memberships.map((m) => m.groupId).toSet();

    return CreditContext(
      userId: userId,
      now: now(),
      records: db
          .select(Tbl.energyRecords, (r) => r['user_id'] == userId)
          .map(EnergyRecord.fromRow)
          .toList(),
      appliances: db
          .select(Tbl.appliances, (r) => r['user_id'] == userId)
          .map(Appliance.fromRow)
          .toList(),
      bookings: db
          .select(Tbl.hubBookings, (r) => r['user_id'] == userId)
          .map(HubBooking.fromRow)
          .toList(),
      memberships: memberships,
      groups: db
          .select(Tbl.arisanGroups, (r) => groupIds.contains(r['id']))
          .map(ArisanGroup.fromRow)
          .toList(),
      payments: db
          .select(Tbl.arisanPayments, (r) => r['user_id'] == userId)
          .map(ArisanPayment.fromRow)
          .toList(),
      installments: db
          .select(Tbl.loanInstallments, (r) => loanIds.contains(r['loan_id']))
          .map(LoanInstallment.fromRow)
          .toList(),
      offers: db
          .select(
            Tbl.quotaOffers,
            (r) => r['owner_id'] == userId || r['counterparty_id'] == userId,
          )
          .map(QuotaOffer.fromRow)
          .toList(),
    );
  }

  String monthLabel(DateTime d) {
    const names = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final m = monthOf(d);
    return '${names[m.month - 1]} ${m.year}';
  }
}
