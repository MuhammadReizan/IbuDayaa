import '../../../features/credit_score/domain/credit_scoring_engine.dart';
import '../../db/ids.dart';
import '../../db/tables.dart';
import '../../errors.dart';
import '../../logic/credit_signals.dart';
import '../../logic/loan_math.dart';
import '../../models/models.dart';
import '../../paths.dart';
import '../repositories.dart';
import 'local_base.dart';

class LocalLoanRepository extends LocalRepo implements LoanRepository {
  LocalLoanRepository(super.db, super.now, this.engine);

  final CreditScoringEngine engine;

  static const int minimumAmountIdr = 500000;

  LoanApplication _loan(String id) {
    final row = db.find(Tbl.loanApplications, id);
    if (row == null) throw const AppException('Pengajuan tidak ditemukan.');
    return LoanApplication.fromRow(row);
  }

  Future<void> _event(
    String loanId,
    String? actorId,
    String type, [
    String? note,
  ]) => db.insert(
    Tbl.loanEvents,
    LoanEvent(
      id: newId(),
      loanId: loanId,
      actorId: actorId,
      type: type,
      note: note,
      createdAt: now(),
    ).toRow(),
  );

  Future<void> _tellMember(
    LoanApplication loan,
    String title,
    String body,
  ) async {
    await notify(
      userId: loan.userId,
      type: 'loan',
      title: title,
      body: body,
      route: Paths.loan(loan.id),
    );
    final thread = supportThreadOf(loan.userId);
    if (thread != null) await postSystemMessage(thread.id, '$title. $body');
  }

  Future<void> _move(
    LoanApplication loan,
    LoanStatus to,
    Map<String, dynamic> extra,
  ) async {
    if (!canTransition(loan.status, to)) {
      throw AppException(
        'Pengajuan berstatus "${loan.status.label}" tidak bisa diubah menjadi '
        '"${to.label}".',
      );
    }
    await db.update(Tbl.loanApplications, loan.id, {'status': to.db, ...extra});
  }

  @override
  Future<LoanApplication> submit({
    required Profile me,
    required int amountIdr,
    required LoanPurpose purpose,
    required int tenorMonths,
    String? note,
  }) async {
    requireMember(me);
    final coop = cooperativeById(me.cooperativeId);
    final score = computeCreditScore(creditContextFor(me.id), engine);
    final hasActive =
        db.first(
          Tbl.loanApplications,
          (r) =>
              r['user_id'] == me.id &&
              LoanStatus.fromDb(r['status'] as String?).isActive,
        ) !=
        null;

    final eligibility = loanEligibility(
      coop: coop,
      score: score,
      hasActiveLoan: hasActive,
    );
    if (!eligibility.canApply) throw AppException(eligibility.message);
    if (amountIdr < minimumAmountIdr) {
      throw const AppException('Nominal minimal Rp 500.000.');
    }
    if (amountIdr > eligibility.ceilingIdr) {
      throw const AppException('Nominal melebihi plafon Anda.');
    }
    if (!coop.loanTenors.contains(tenorMonths)) {
      throw const AppException('Tenor ini tidak disediakan koperasi.');
    }

    final quote = quoteLoan(
      principalIdr: amountIdr,
      tenorMonths: tenorMonths,
      flatMonthlyRatePct: coop.loanFlatMonthlyRatePct,
    );

    return db.transaction(() async {
      final loan = LoanApplication(
        id: newId(),
        cooperativeId: coop.id,
        userId: me.id,
        amountIdr: amountIdr,
        purpose: purpose,
        tenorMonths: tenorMonths,
        flatMonthlyRatePct: coop.loanFlatMonthlyRatePct,
        monthlyInstallmentIdr: quote.monthlyInstallmentIdr,
        totalRepaymentIdr: quote.totalRepaymentIdr,
        note: (note == null || note.trim().isEmpty) ? null : note.trim(),
        scoreSnapshot: score!.score,
        scoreBand: score.band.label,
        scoreFactors: [
          for (final f in score.factors)
            ScoreFactorSnapshot(
              label: f.label,
              points: f.points,
              maxPoints: f.maxPoints,
            ),
        ],
        status: LoanStatus.submitted,
        createdAt: now(),
      );
      await db.insert(Tbl.loanApplications, loan.toRow());
      await _event(loan.id, me.id, LoanStatus.submitted.db);
      await notifyAdmins(
        cooperativeId: coop.id,
        type: 'loan',
        title: 'Pengajuan pinjaman baru',
        body:
            '${me.fullName} mengajukan Rp${_thousands(amountIdr)} '
            'untuk ${purpose.label.toLowerCase()}.',
        route: Paths.adminLoan(loan.id),
      );
      final thread = supportThreadOf(me.id);
      if (thread != null) {
        await postSystemMessage(
          thread.id,
          'Pengajuan pinjaman Rp${_thousands(amountIdr)} terkirim dan '
          'menunggu review admin.',
        );
      }
      return loan;
    });
  }

  @override
  Future<void> cancel({required Profile me, required String loanId}) async {
    final loan = _loan(loanId);
    if (loan.userId != me.id) {
      throw const AppException('Anda tidak bisa membatalkan pengajuan ini.');
    }
    if (loan.status != LoanStatus.submitted) {
      throw const AppException(
        'Pengajuan yang sudah direview tidak bisa dibatalkan sendiri. '
        'Hubungi admin.',
      );
    }
    await db.transaction(() async {
      await _move(loan, LoanStatus.cancelled, {});
      await _event(loan.id, me.id, LoanStatus.cancelled.db);
      await notifyAdmins(
        cooperativeId: loan.cooperativeId,
        type: 'loan',
        title: 'Pengajuan dibatalkan anggota',
        body: '${me.fullName} membatalkan pengajuannya.',
        route: Paths.adminLoan(loan.id),
      );
    });
  }

  @override
  Future<void> startReview({
    required Profile admin,
    required String loanId,
  }) async {
    final loan = _loan(loanId);
    requireAdmin(admin, loan.cooperativeId);
    await db.transaction(() async {
      await _move(loan, LoanStatus.inReview, {});
      await _event(loan.id, admin.id, LoanStatus.inReview.db);
      await _tellMember(
        loan,
        'Pengajuan sedang direview',
        'Admin ${admin.fullName} sedang memeriksa pengajuan Anda.',
      );
    });
  }

  @override
  Future<void> approve({
    required Profile admin,
    required String loanId,
    String? note,
  }) async {
    final loan = _loan(loanId);
    requireAdmin(admin, loan.cooperativeId);
    final clean = (note == null || note.trim().isEmpty) ? null : note.trim();
    await db.transaction(() async {
      await _move(loan, LoanStatus.approved, {
        'decision_note': clean,
        'decided_by': admin.id,
        'decided_at': now().toIso8601String(),
      });
      await _event(loan.id, admin.id, LoanStatus.approved.db, clean);
      await _tellMember(
        loan,
        'Pengajuan disetujui',
        'Admin menyetujui Rp${_thousands(loan.amountIdr)}. Dana akan '
            'dicairkan oleh koperasi.${clean == null ? '' : ' Catatan: $clean'}',
      );
    });
  }

  @override
  Future<void> reject({
    required Profile admin,
    required String loanId,
    required String reason,
  }) async {
    final loan = _loan(loanId);
    requireAdmin(admin, loan.cooperativeId);
    if (reason.trim().isEmpty) {
      throw const AppException('Tulis alasan penolakan agar anggota paham.');
    }
    await db.transaction(() async {
      await _move(loan, LoanStatus.rejected, {
        'decision_note': reason.trim(),
        'decided_by': admin.id,
        'decided_at': now().toIso8601String(),
      });
      await _event(loan.id, admin.id, LoanStatus.rejected.db, reason.trim());
      await _tellMember(
        loan,
        'Pengajuan belum disetujui',
        'Alasan dari admin: ${reason.trim()}',
      );
    });
  }

  @override
  Future<void> disburse({
    required Profile admin,
    required String loanId,
  }) async {
    final loan = _loan(loanId);
    requireAdmin(admin, loan.cooperativeId);
    final t = now();
    await db.transaction(() async {
      await _move(loan, LoanStatus.disbursed, {
        'disbursed_at': t.toIso8601String(),
      });
      for (final i in installmentSchedule(
        totalIdr: loan.totalRepaymentIdr,
        tenorMonths: loan.tenorMonths,
        disbursedAt: t,
      )) {
        await db.insert(
          Tbl.loanInstallments,
          LoanInstallment(
            id: newId(),
            loanId: loan.id,
            seq: i.seq,
            dueDate: i.due,
            amountIdr: i.amountIdr,
          ).toRow(),
        );
      }
      await _event(loan.id, admin.id, LoanStatus.disbursed.db);
      await _tellMember(
        loan,
        'Dana pinjaman dicairkan',
        'Cicilan Rp${_thousands(loan.monthlyInstallmentIdr)} per bulan '
            'selama ${loan.tenorMonths} bulan mulai bulan depan.',
      );
    });
  }

  @override
  Future<void> markInstallmentPaid({
    required Profile admin,
    required String installmentId,
  }) async {
    final row = db.find(Tbl.loanInstallments, installmentId);
    if (row == null) throw const AppException('Cicilan tidak ditemukan.');
    final installment = LoanInstallment.fromRow(row);
    final loan = _loan(installment.loanId);
    requireAdmin(admin, loan.cooperativeId);
    if (loan.status != LoanStatus.disbursed) {
      throw const AppException('Pinjaman ini tidak sedang berjalan.');
    }
    if (installment.isPaid) {
      throw const AppException('Cicilan ini sudah dicatat lunas.');
    }

    await db.transaction(() async {
      await db.update(Tbl.loanInstallments, installmentId, {
        'paid_at': now().toIso8601String(),
        'confirmed_by': admin.id,
      });
      await _event(
        loan.id,
        admin.id,
        'installment_paid',
        'Cicilan ke-${installment.seq}',
      );
      final unpaid = db.first(
        Tbl.loanInstallments,
        (r) => r['loan_id'] == loan.id && r['paid_at'] == null,
      );
      if (unpaid == null) {
        await _move(loan, LoanStatus.repaid, {});
        await _event(loan.id, admin.id, LoanStatus.repaid.db);
        await _tellMember(
          loan,
          'Pinjaman lunas',
          'Terima kasih. Semua cicilan sudah tercatat lunas.',
        );
      } else {
        await notify(
          userId: loan.userId,
          type: 'loan',
          title: 'Cicilan ke-${installment.seq} tercatat',
          body:
              'Pembayaran Rp${_thousands(installment.amountIdr)} sudah '
              'dikonfirmasi admin.',
          route: Paths.loan(loan.id),
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
