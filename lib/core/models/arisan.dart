import 'package:flutter/foundation.dart';

import '../db/row.dart';

@immutable
class ArisanGroup {
  const ArisanGroup({
    required this.id,
    required this.cooperativeId,
    required this.name,
    required this.contributionIdr,
    required this.startMonth,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String cooperativeId;
  final String name;
  final int contributionIdr;
  final DateTime startMonth;
  final String createdBy;
  final DateTime createdAt;

  factory ArisanGroup.fromRow(Map<String, dynamic> r) => ArisanGroup(
    id: rStr(r, 'id'),
    cooperativeId: rStr(r, 'cooperative_id'),
    name: rStr(r, 'name'),
    contributionIdr: rInt(r, 'contribution_idr'),
    startMonth: monthOf(rDate(r, 'start_month')),
    createdBy: rStr(r, 'created_by'),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'cooperative_id': cooperativeId,
    'name': name,
    'contribution_idr': contributionIdr,
    'start_month': dateOnly(startMonth),
    'created_by': createdBy,
    'created_at': ts(createdAt),
  };
}

@immutable
class ArisanMember {
  const ArisanMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.turnOrder,
    required this.joinedAt,
  });

  final String id;
  final String groupId;
  final String userId;

  /// 1-based; turn N receives the pot in `startMonth + (N - 1)` months.
  final int turnOrder;
  final DateTime joinedAt;

  factory ArisanMember.fromRow(Map<String, dynamic> r) => ArisanMember(
    id: rStr(r, 'id'),
    groupId: rStr(r, 'group_id'),
    userId: rStr(r, 'user_id'),
    turnOrder: rInt(r, 'turn_order', 1),
    joinedAt: rDate(r, 'joined_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'group_id': groupId,
    'user_id': userId,
    'turn_order': turnOrder,
    'joined_at': ts(joinedAt),
  };
}

enum PaymentType {
  contribution,
  payout;

  static PaymentType fromDb(String? v) => v == 'payout' ? payout : contribution;
  String get db => name;
  String get label => this == payout ? 'Pencairan giliran' : 'Setoran iuran';
}

enum PaymentStatus {
  pending,
  confirmed,
  rejected;

  static PaymentStatus fromDb(String? v) => switch (v) {
    'confirmed' => confirmed,
    'rejected' => rejected,
    _ => pending,
  };

  String get db => name;

  String get label => switch (this) {
    pending => 'Menunggu konfirmasi',
    confirmed => 'Terkonfirmasi',
    rejected => 'Ditolak',
  };
}

@immutable
class ArisanPayment {
  const ArisanPayment({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.type,
    required this.amountIdr,
    required this.periodMonth,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String userId;
  final PaymentType type;
  final int amountIdr;
  final DateTime periodMonth;
  final PaymentStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? note;
  final DateTime createdAt;

  factory ArisanPayment.fromRow(Map<String, dynamic> r) => ArisanPayment(
    id: rStr(r, 'id'),
    groupId: rStr(r, 'group_id'),
    userId: rStr(r, 'user_id'),
    type: PaymentType.fromDb(rStrN(r, 'type')),
    amountIdr: rInt(r, 'amount_idr'),
    periodMonth: monthOf(rDate(r, 'period_month')),
    status: PaymentStatus.fromDb(rStrN(r, 'status')),
    reviewedBy: rStrN(r, 'reviewed_by'),
    reviewedAt: rDateN(r, 'reviewed_at'),
    note: rStrN(r, 'note'),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'group_id': groupId,
    'user_id': userId,
    'type': type.db,
    'amount_idr': amountIdr,
    'period_month': dateOnly(periodMonth),
    'status': status.db,
    'reviewed_by': reviewedBy,
    'reviewed_at': reviewedAt == null ? null : ts(reviewedAt!),
    'note': note,
    'created_at': ts(createdAt),
  };
}

/// "Saya ingin berbagi kuota" or "Saya butuh kuota".
enum QuotaKind {
  share,
  need;

  static QuotaKind fromDb(String? v) => v == 'need' ? need : share;
  String get db => name;
}

enum QuotaStatus {
  open,
  pending,
  completed,
  cancelled;

  static QuotaStatus fromDb(String? v) => switch (v) {
    'pending' => pending,
    'completed' => completed,
    'cancelled' => cancelled,
    _ => open,
  };

  String get db => name;
}

/// An agreement to hand hub quota from one member to another. No electricity
/// moves — the giver books less, the receiver may book more.
@immutable
class QuotaOffer {
  const QuotaOffer({
    required this.id,
    required this.cooperativeId,
    required this.ownerId,
    required this.kind,
    required this.kwh,
    required this.slotNote,
    this.note,
    required this.status,
    this.counterpartyId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String cooperativeId;
  final String ownerId;
  final QuotaKind kind;
  final double kwh;
  final String slotNote;
  final String? note;
  final QuotaStatus status;
  final String? counterpartyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Who gives the quota once the exchange completes.
  String? get giverId => kind == QuotaKind.share ? ownerId : counterpartyId;

  /// Who receives it.
  String? get receiverId => kind == QuotaKind.share ? counterpartyId : ownerId;

  factory QuotaOffer.fromRow(Map<String, dynamic> r) => QuotaOffer(
    id: rStr(r, 'id'),
    cooperativeId: rStr(r, 'cooperative_id'),
    ownerId: rStr(r, 'owner_id'),
    kind: QuotaKind.fromDb(rStrN(r, 'kind')),
    kwh: rDbl(r, 'kwh'),
    slotNote: rStr(r, 'slot_note'),
    note: rStrN(r, 'note'),
    status: QuotaStatus.fromDb(rStrN(r, 'status')),
    counterpartyId: rStrN(r, 'counterparty_id'),
    createdAt: rDate(r, 'created_at'),
    updatedAt: rDate(r, 'updated_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'cooperative_id': cooperativeId,
    'owner_id': ownerId,
    'kind': kind.db,
    'kwh': kwh,
    'slot_note': slotNote,
    'note': note,
    'status': status.db,
    'counterparty_id': counterpartyId,
    'created_at': ts(createdAt),
    'updated_at': ts(updatedAt),
  };
}
