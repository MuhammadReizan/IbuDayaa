import 'dart:ui' show Locale;

import '../../../features/credit_score/domain/credit_scoring_engine.dart';
import '../../l10n/l10n.dart';
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

  /// English text for [AppException.en].
  static final AppLocalizations _en = AppLocalizations.forLocale(
    const Locale('en'),
  );

  static const int minimumAmountIdr = 500000;

  LoanApplication _loan(String id) {
    final row = db.find(Tbl.loanApplications, id);
    if (row == null) {
      throw const AppException(
        'Pengajuan tidak ditemukan.',
        en: 'Application not found.',
      );
    }
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
    String body, {
    required String titleEn,
    required String bodyEn,
  }) async {
    await notify(
      userId: loan.userId,
      type: 'loan',
      title: title,
      body: body,
      titleEn: titleEn,
      bodyEn: bodyEn,
      route: Paths.loan(loan.id),
    );
    final thread = supportThreadOf(loan.userId);
    if (thread != null) {
      await postSystemMessage(
        thread.id,
        '$title. $body',
        bodyEn: '$titleEn. $bodyEn',
      );
    }
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
        en:
            'An application with status "${loan.status.localizedLabel(_en)}" '
            'cannot be changed to "${to.localizedLabel(_en)}".',
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
    if (!eligibility.canApply) {
      throw AppException(
        eligibility.message,
        en: eligibility.localizedMessage(_en),
      );
    }
    if (amountIdr < minimumAmountIdr) {
      throw const AppException(
        'Nominal minimal Rp 500.000.',
        en: 'The minimum amount is Rp 500,000.',
      );
    }
    if (amountIdr > eligibility.ceilingIdr) {
      throw const AppException(
        'Nominal melebihi plafon Anda.',
        en: 'The amount exceeds your limit.',
      );
    }
    if (!coop.loanTenors.contains(tenorMonths)) {
      throw const AppException(
        'Tenor ini tidak disediakan koperasi.',
        en: 'The cooperative doesn\'t offer this term.',
      );
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
              labelEn: f.labelEn,
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
        titleEn: 'New loan application',
        bodyEn:
            '${me.fullName} applied for Rp${_thousands(amountIdr, ",")} '
            'for ${purpose.localizedLabel(_en).toLowerCase()}.',
        route: Paths.adminLoan(loan.id),
      );
      final thread = supportThreadOf(me.id);
      if (thread != null) {
        await postSystemMessage(
          thread.id,
          'Pengajuan pinjaman Rp${_thousands(amountIdr)} terkirim dan '
          'menunggu review admin.',
          bodyEn:
              'Your loan application of Rp${_thousands(amountIdr, ",")} was '
              'sent and is waiting for admin review.',
        );
      }
      return loan;
    });
  }

  @override
  Future<void> cancel({required Profile me, required String loanId}) async {
    final loan = _loan(loanId);
    if (loan.userId != me.id) {
      throw const AppException(
        'Anda tidak bisa membatalkan pengajuan ini.',
        en: 'You can\'t cancel this application.',
      );
    }
    if (loan.status != LoanStatus.submitted) {
      throw const AppException(
        'Pengajuan yang sudah direview tidak bisa dibatalkan sendiri. '
        'Hubungi admin.',
        en: 'An application that has already been reviewed cannot be cancelled by you. Contact the admin.',
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
        titleEn: 'Application cancelled by the member',
        bodyEn: '${me.fullName} cancelled their application.',
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
        titleEn: 'Application under review',
        bodyEn: 'Admin ${admin.fullName} is reviewing your application.',
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
        titleEn: 'Application approved',
        bodyEn:
            'The admin approved Rp${_thousands(loan.amountIdr, ",")}. The '
            'cooperative will disburse the funds.'
            '${clean == null ? '' : ' Note: $clean'}',
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
      throw const AppException(
        'Tulis alasan penolakan agar anggota paham.',
        en: 'Write the reason for rejecting so the member understands.',
      );
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
        titleEn: 'Application not approved',
        bodyEn: 'Reason from the admin: ${reason.trim()}',
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
        titleEn: 'Loan funds disbursed',
        bodyEn:
            'Installments of Rp${_thousands(loan.monthlyInstallmentIdr, ",")} '
            'per month for ${loan.tenorMonths} months, starting next month.',
      );
    });
  }

  @override
  Future<void> markInstallmentPaid({
    required Profile admin,
    required String installmentId,
  }) async {
    final row = db.find(Tbl.loanInstallments, installmentId);
    if (row == null) {
      throw const AppException(
        'Cicilan tidak ditemukan.',
        en: 'Installment not found.',
      );
    }
    final installment = LoanInstallment.fromRow(row);
    final loan = _loan(installment.loanId);
    requireAdmin(admin, loan.cooperativeId);
    if (loan.status != LoanStatus.disbursed) {
      throw const AppException(
        'Pinjaman ini tidak sedang berjalan.',
        en: 'This loan isn\'t active.',
      );
    }
    if (installment.isPaid) {
      throw const AppException(
        'Cicilan ini sudah dicatat lunas.',
        en: 'This installment is already recorded as paid.',
      );
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
          titleEn: 'Loan repaid',
          bodyEn: 'Thank you. All installments are recorded as paid.',
        );
      } else {
        await notify(
          userId: loan.userId,
          type: 'loan',
          title: 'Cicilan ke-${installment.seq} tercatat',
          body:
              'Pembayaran Rp${_thousands(installment.amountIdr)} sudah '
              'dikonfirmasi admin.',
          titleEn: 'Installment ${installment.seq} recorded',
          bodyEn:
              'Payment of Rp${_thousands(installment.amountIdr, ",")} was '
              'confirmed by the admin.',
          route: Paths.loan(loan.id),
        );
      }
    });
  }

  @override
  Future<void> submitInstallmentPayment({
    required Profile me,
    required String installmentId,
    String? note,
  }) async {
    requireMember(me);
    final row = db.find(Tbl.loanInstallments, installmentId);
    final installment = row == null ? null : LoanInstallment.fromRow(row);
    final loan = installment == null ? null : _loan(installment.loanId);
    if (installment == null || loan == null || loan.userId != me.id) {
      throw const AppException(
        'Cicilan tidak ditemukan.',
        en: 'Installment not found.',
      );
    }
    if (loan.status != LoanStatus.disbursed) {
      throw const AppException(
        'Pinjaman ini tidak sedang berjalan.',
        en: 'This loan isn\'t active.',
      );
    }
    if (installment.isPaid) {
      throw const AppException(
        'Cicilan ini sudah dicatat lunas.',
        en: 'This installment is already recorded as paid.',
      );
    }
    if (installment.isAwaitingConfirmation) {
      throw const AppException(
        'Pembayaran ini sudah dikirim dan menunggu konfirmasi admin.',
        en: 'This payment has been sent and is waiting for admin confirmation.',
      );
    }
    final earlierOpen = db.first(
      Tbl.loanInstallments,
      (r) =>
          r['loan_id'] == loan.id &&
          (r['seq'] as num) < installment.seq &&
          r['paid_at'] == null &&
          r['payment_submitted_at'] == null,
    );
    if (earlierOpen != null) {
      throw const AppException(
        'Bayar cicilan sebelumnya dulu.',
        en: 'Pay the earlier installment first.',
      );
    }

    final clean = (note == null || note.trim().isEmpty) ? null : note.trim();
    await db.transaction(() async {
      await db.update(Tbl.loanInstallments, installmentId, {
        'payment_submitted_at': now().toIso8601String(),
        'payment_note': clean,
        'review_note': null,
      });
      await _event(
        loan.id,
        me.id,
        'installment_submitted',
        'Cicilan ke-${installment.seq}',
      );
      await notifyAdmins(
        cooperativeId: loan.cooperativeId,
        type: 'payment',
        title: 'Cicilan menunggu konfirmasi',
        body:
            '${me.fullName} membayar cicilan ke-${installment.seq} '
            '(Rp${_thousands(installment.amountIdr)}).',
        titleEn: 'Installment awaiting confirmation',
        bodyEn:
            '${me.fullName} paid installment ${installment.seq} '
            '(Rp${_thousands(installment.amountIdr, ",")}).',
        route: Paths.adminInstallments,
      );
    });
  }

  @override
  Future<void> rejectInstallmentPayment({
    required Profile admin,
    required String installmentId,
    required String reason,
  }) async {
    final row = db.find(Tbl.loanInstallments, installmentId);
    if (row == null) {
      throw const AppException(
        'Cicilan tidak ditemukan.',
        en: 'Installment not found.',
      );
    }
    final installment = LoanInstallment.fromRow(row);
    final loan = _loan(installment.loanId);
    requireAdmin(admin, loan.cooperativeId);
    if (!installment.isAwaitingConfirmation) {
      throw const AppException(
        'Tidak ada pembayaran cicilan yang menunggu konfirmasi.',
        en: 'There is no installment payment waiting for confirmation.',
      );
    }
    final clean = reason.trim();
    if (clean.isEmpty) {
      throw const AppException(
        'Tulis alasan penolakan agar anggota paham.',
        en: 'Write the reason for rejecting so the member understands.',
      );
    }

    await db.transaction(() async {
      await db.update(Tbl.loanInstallments, installmentId, {
        'payment_submitted_at': null,
        'review_note': clean,
      });
      await _event(
        loan.id,
        admin.id,
        'installment_rejected',
        'Cicilan ke-${installment.seq}: $clean',
      );
      await notify(
        userId: loan.userId,
        type: 'loan',
        title: 'Pembayaran cicilan ditolak',
        body: 'Cicilan ke-${installment.seq} belum diterima: $clean',
        titleEn: 'Installment payment rejected',
        bodyEn: 'Installment ${installment.seq} was not received: $clean',
        route: Paths.installments,
      );
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
