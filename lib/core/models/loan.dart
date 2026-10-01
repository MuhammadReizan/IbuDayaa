import 'package:flutter/foundation.dart';

import '../db/row.dart';

import '../l10n/l10n.dart';

enum LoanStatus {
  submitted,
  inReview,
  approved,
  rejected,
  disbursed,
  repaid,
  cancelled;

  static LoanStatus fromDb(String? v) => switch (v) {
    'in_review' => inReview,
    'approved' => approved,
    'rejected' => rejected,
    'disbursed' => disbursed,
    'repaid' => repaid,
    'cancelled' => cancelled,
    _ => submitted,
  };

  String get db => switch (this) {
    inReview => 'in_review',
    _ => name,
  };

  String get label => switch (this) {
    submitted => 'Terkirim',
    inReview => 'Sedang direview',
    approved => 'Disetujui admin',
    rejected => 'Ditolak',
    disbursed => 'Dana dicairkan',
    repaid => 'Lunas',
    cancelled => 'Dibatalkan',
  };

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    submitted => l10n.loanStatusSubmitted,
    inReview => l10n.loanStatusInReview,
    approved => l10n.loanStatusApproved,
    rejected => l10n.loanStatusRejected,
    disbursed => l10n.loanStatusDisbursed,
    repaid => l10n.loanStatusRepaid,
    cancelled => l10n.loanStatusCancelled,
  };

  /// Still open — a member may hold only one at a time.
  bool get isActive =>
      this == submitted ||
      this == inReview ||
      this == approved ||
      this == disbursed;

  bool get isFinal => this == rejected || this == repaid || this == cancelled;
}

enum LoanPurpose {
  rawMaterial,
  equipment,
  renovation,
  other;

  static LoanPurpose fromDb(String? v) => switch (v) {
    'raw_material' => rawMaterial,
    'equipment' => equipment,
    'renovation' => renovation,
    _ => other,
  };

  String get db => switch (this) {
    rawMaterial => 'raw_material',
    equipment => 'equipment',
    renovation => 'renovation',
    other => 'other',
  };

  String get label => switch (this) {
    rawMaterial => 'Bahan baku',
    equipment => 'Alat produksi',
    renovation => 'Renovasi tempat usaha',
    other => 'Lainnya',
  };

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    rawMaterial => l10n.loanPurposeRawMaterial,
    equipment => l10n.loanPurposeEquipment,
    renovation => l10n.loanPurposeRenovation,
    other => l10n.loanPurposeOther,
  };
}

@immutable
class ScoreFactorSnapshot {
  const ScoreFactorSnapshot({
    required this.label,
    required this.points,
    required this.maxPoints,
    this.labelEn,
  });

  final String label;

  /// English label, kept with the snapshot so an old application still reads
  /// in either language. Null on snapshots saved before it existed.
  final String? labelEn;
  final int points;
  final int maxPoints;

  String labelFor({required bool english}) =>
      english ? (labelEn ?? label) : label;

  factory ScoreFactorSnapshot.fromJson(Map<String, dynamic> j) =>
      ScoreFactorSnapshot(
        label: rStr(j, 'label'),
        labelEn: rStrN(j, 'label_en'),
        points: rInt(j, 'points'),
        maxPoints: rInt(j, 'max_points'),
      );

  Map<String, dynamic> toJson() => {
    'label': label,
    if (labelEn != null) 'label_en': labelEn,
    'points': points,
    'max_points': maxPoints,
  };
}

@immutable
class LoanApplication {
  const LoanApplication({
    required this.id,
    required this.cooperativeId,
    required this.userId,
    required this.amountIdr,
    required this.purpose,
    required this.tenorMonths,
    required this.flatMonthlyRatePct,
    required this.monthlyInstallmentIdr,
    required this.totalRepaymentIdr,
    this.note,
    required this.scoreSnapshot,
    required this.scoreBand,
    required this.scoreFactors,
    required this.status,
    this.decisionNote,
    this.decidedBy,
    this.decidedAt,
    this.disbursedAt,
    required this.createdAt,
  });

  final String id;
  final String cooperativeId;
  final String userId;
  final int amountIdr;
  final LoanPurpose purpose;
  final int tenorMonths;

  /// The cooperative's rate at the moment of applying. Later policy changes do
  /// not rewrite an application the member already agreed to.
  final double flatMonthlyRatePct;
  final int monthlyInstallmentIdr;
  final int totalRepaymentIdr;
  final String? note;

  /// The score exactly as the member saw it when they applied, so the admin
  /// reviews the same numbers.
  final int scoreSnapshot;
  final String scoreBand;
  final List<ScoreFactorSnapshot> scoreFactors;
  final LoanStatus status;
  final String? decisionNote;
  final String? decidedBy;
  final DateTime? decidedAt;
  final DateTime? disbursedAt;
  final DateTime createdAt;

  factory LoanApplication.fromRow(Map<String, dynamic> r) => LoanApplication(
    id: rStr(r, 'id'),
    cooperativeId: rStr(r, 'cooperative_id'),
    userId: rStr(r, 'user_id'),
    amountIdr: rInt(r, 'amount_idr'),
    purpose: LoanPurpose.fromDb(rStrN(r, 'purpose')),
    tenorMonths: rInt(r, 'tenor_months'),
    flatMonthlyRatePct: rDbl(r, 'flat_monthly_rate_pct'),
    monthlyInstallmentIdr: rInt(r, 'monthly_installment_idr'),
    totalRepaymentIdr: rInt(r, 'total_repayment_idr'),
    note: rStrN(r, 'note'),
    scoreSnapshot: rInt(r, 'score_snapshot'),
    scoreBand: rStr(r, 'score_band'),
    scoreFactors: [
      for (final f in (r['score_factors'] as List?) ?? const [])
        if (f is Map)
          ScoreFactorSnapshot.fromJson(Map<String, dynamic>.from(f)),
    ],
    status: LoanStatus.fromDb(rStrN(r, 'status')),
    decisionNote: rStrN(r, 'decision_note'),
    decidedBy: rStrN(r, 'decided_by'),
    decidedAt: rDateN(r, 'decided_at'),
    disbursedAt: rDateN(r, 'disbursed_at'),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'cooperative_id': cooperativeId,
    'user_id': userId,
    'amount_idr': amountIdr,
    'purpose': purpose.db,
    'tenor_months': tenorMonths,
    'flat_monthly_rate_pct': flatMonthlyRatePct,
    'monthly_installment_idr': monthlyInstallmentIdr,
    'total_repayment_idr': totalRepaymentIdr,
    'note': note,
    'score_snapshot': scoreSnapshot,
    'score_band': scoreBand,
    'score_factors': [for (final f in scoreFactors) f.toJson()],
    'status': status.db,
    'decision_note': decisionNote,
    'decided_by': decidedBy,
    'decided_at': decidedAt == null ? null : ts(decidedAt!),
    'disbursed_at': disbursedAt == null ? null : ts(disbursedAt!),
    'created_at': ts(createdAt),
  };
}

@immutable
class LoanInstallment {
  const LoanInstallment({
    required this.id,
    required this.loanId,
    required this.seq,
    required this.dueDate,
    required this.amountIdr,
    this.paidAt,
    this.confirmedBy,
    this.submittedAt,
    this.submitNote,
    this.reviewNote,
  });

  final String id;
  final String loanId;
  final int seq;
  final DateTime dueDate;
  final int amountIdr;

  /// When an admin confirmed (or recorded) the payment.
  final DateTime? paidAt;
  final String? confirmedBy;

  /// When the member told the cooperative she paid, same as an arisan dues
  /// payment: it waits for an admin to confirm. Cleared when the admin rejects
  /// it, so the member can send it again.
  final DateTime? submittedAt;
  final String? submitNote;

  /// Why the admin rejected the last payment the member sent.
  final String? reviewNote;

  bool get isPaid => paidAt != null;

  /// Sent by the member, not yet confirmed or rejected by an admin.
  bool get isAwaitingConfirmation => !isPaid && submittedAt != null;

  /// The last payment she sent was rejected and she hasn't sent another.
  bool get wasRejected => !isPaid && submittedAt == null && reviewNote != null;

  bool isOverdue(DateTime now) => !isPaid && dayOf(now).isAfter(dueDate);

  /// Judged on the day the member paid, not on the day an admin got round to
  /// confirming it — otherwise a slow confirmation would count against her.
  bool get paidOnTime =>
      isPaid && !dayOf(submittedAt ?? paidAt!).isAfter(dueDate);

  factory LoanInstallment.fromRow(Map<String, dynamic> r) => LoanInstallment(
    id: rStr(r, 'id'),
    loanId: rStr(r, 'loan_id'),
    seq: rInt(r, 'seq'),
    dueDate: dayOf(rDate(r, 'due_date')),
    amountIdr: rInt(r, 'amount_idr'),
    paidAt: rDateN(r, 'paid_at'),
    confirmedBy: rStrN(r, 'confirmed_by'),
    submittedAt: rDateN(r, 'payment_submitted_at'),
    submitNote: rStrN(r, 'payment_note'),
    reviewNote: rStrN(r, 'review_note'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'loan_id': loanId,
    'seq': seq,
    'due_date': dateOnly(dueDate),
    'amount_idr': amountIdr,
    'paid_at': paidAt == null ? null : ts(paidAt!),
    'confirmed_by': confirmedBy,
    'payment_submitted_at': submittedAt == null ? null : ts(submittedAt!),
    'payment_note': submitNote,
    'review_note': reviewNote,
  };
}

@immutable
class LoanEvent {
  const LoanEvent({
    required this.id,
    required this.loanId,
    this.actorId,
    required this.type,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String loanId;
  final String? actorId;

  /// The status it moved to, or 'installment_paid'.
  final String type;
  final String? note;
  final DateTime createdAt;

  factory LoanEvent.fromRow(Map<String, dynamic> r) => LoanEvent(
    id: rStr(r, 'id'),
    loanId: rStr(r, 'loan_id'),
    actorId: rStrN(r, 'actor_id'),
    type: rStr(r, 'type'),
    note: rStrN(r, 'note'),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'loan_id': loanId,
    'actor_id': actorId,
    'type': type,
    'note': note,
    'created_at': ts(createdAt),
  };
}
