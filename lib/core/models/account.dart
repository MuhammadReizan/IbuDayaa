import 'package:flutter/foundation.dart';

import '../db/row.dart';

import '../l10n/l10n.dart';

enum UserRole {
  member,
  admin;

  static UserRole fromDb(String? v) => v == 'admin' ? admin : member;
  String get db => name;
  String get label => this == admin ? 'Admin Koperasi' : 'Anggota';
  String localizedLabel(AppLocalizations l10n) =>
      this == admin ? l10n.roleAdmin : l10n.roleMember;
}

@immutable
class Profile {
  const Profile({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.businessName,
    required this.city,
    required this.role,
    required this.cooperativeId,
    required this.tariffIdrPerKwh,
    required this.createdAt,
  });

  final String id;

  /// E.164, e.g. `+6281234567890`.
  final String phone;
  final String fullName;
  final String businessName;
  final String city;
  final UserRole role;
  final String cooperativeId;

  /// PLN tariff the member pays. Every rupiah figure derives from it.
  final double tariffIdrPerKwh;
  final DateTime createdAt;

  bool get isAdmin => role == UserRole.admin;

  String get greetingName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.length <= 2 ? fullName.trim() : parts.take(2).join(' ');
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// `+6281234567890` → `0812-3456-7890`.
  String get displayPhone {
    final local = phone.startsWith('+62') ? '0${phone.substring(3)}' : phone;
    final b = StringBuffer();
    for (int i = 0; i < local.length; i++) {
      if (i == 4 || i == 8) b.write('-');
      b.write(local[i]);
    }
    return b.toString();
  }

  Profile copyWith({
    String? fullName,
    String? businessName,
    String? city,
    double? tariffIdrPerKwh,
  }) => Profile(
    id: id,
    phone: phone,
    fullName: fullName ?? this.fullName,
    businessName: businessName ?? this.businessName,
    city: city ?? this.city,
    role: role,
    cooperativeId: cooperativeId,
    tariffIdrPerKwh: tariffIdrPerKwh ?? this.tariffIdrPerKwh,
    createdAt: createdAt,
  );

  factory Profile.fromRow(Map<String, dynamic> r) => Profile(
    id: rStr(r, 'id'),
    phone: rStr(r, 'phone'),
    fullName: rStr(r, 'full_name'),
    businessName: rStr(r, 'business_name'),
    city: rStr(r, 'city'),
    role: UserRole.fromDb(rStrN(r, 'role')),
    cooperativeId: rStr(r, 'cooperative_id'),
    tariffIdrPerKwh: rDbl(r, 'tariff_idr_per_kwh', 1444.70),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'phone': phone,
    'full_name': fullName,
    'business_name': businessName,
    'city': city,
    'role': role.db,
    'cooperative_id': cooperativeId,
    'tariff_idr_per_kwh': tariffIdrPerKwh,
    'created_at': ts(createdAt),
  };
}

/// A cooperative and the policy its admins set. The loan and quota numbers are
/// the cooperative's own decisions — the app enforces them, it does not pick
/// them.
@immutable
class Cooperative {
  const Cooperative({
    required this.id,
    required this.name,
    required this.city,
    required this.inviteCode,
    required this.createdBy,
    this.loanFlatMonthlyRatePct = 2.0,
    this.loanMaxAmountIdr = 5000000,
    this.loanMinScore = 60,
    this.loanTenors = const [3, 6, 12],
    this.memberMonthlyQuotaKwh = 30,
    this.solarCostPerKwpIdr = 15000000,
    this.arisanBankAccount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String city;
  final String inviteCode;
  final String createdBy;
  final double loanFlatMonthlyRatePct;
  final int loanMaxAmountIdr;
  final int loanMinScore;
  final List<int> loanTenors;

  /// Hub energy each member may book or share per month.
  final double memberMonthlyQuotaKwh;

  /// Installed cost per kWp, used for the roof payback estimate.
  final int solarCostPerKwpIdr;

  /// Where a member transfers arisan dues if she doesn't hand cash to the
  /// treasurer directly, e.g. "BCA 1234567890 a.n. Koperasi Energi Melati".
  /// Free text, set once by the admin. Null/empty means the app only offers
  /// "cash to the treasurer" as an instruction — it never implies a transfer
  /// option with no destination to send it to.
  final String? arisanBankAccount;
  final DateTime createdAt;

  Cooperative copyWith({
    String? name,
    String? city,
    String? inviteCode,
    double? loanFlatMonthlyRatePct,
    int? loanMaxAmountIdr,
    int? loanMinScore,
    List<int>? loanTenors,
    double? memberMonthlyQuotaKwh,
    int? solarCostPerKwpIdr,
    String? arisanBankAccount,
  }) => Cooperative(
    id: id,
    name: name ?? this.name,
    city: city ?? this.city,
    inviteCode: inviteCode ?? this.inviteCode,
    createdBy: createdBy,
    loanFlatMonthlyRatePct:
        loanFlatMonthlyRatePct ?? this.loanFlatMonthlyRatePct,
    loanMaxAmountIdr: loanMaxAmountIdr ?? this.loanMaxAmountIdr,
    loanMinScore: loanMinScore ?? this.loanMinScore,
    loanTenors: loanTenors ?? this.loanTenors,
    memberMonthlyQuotaKwh: memberMonthlyQuotaKwh ?? this.memberMonthlyQuotaKwh,
    solarCostPerKwpIdr: solarCostPerKwpIdr ?? this.solarCostPerKwpIdr,
    arisanBankAccount: arisanBankAccount ?? this.arisanBankAccount,
    createdAt: createdAt,
  );

  factory Cooperative.fromRow(Map<String, dynamic> r) => Cooperative(
    id: rStr(r, 'id'),
    name: rStr(r, 'name'),
    city: rStr(r, 'city'),
    inviteCode: rStr(r, 'invite_code'),
    createdBy: rStr(r, 'created_by'),
    loanFlatMonthlyRatePct: rDbl(r, 'loan_flat_monthly_rate_pct', 2.0),
    loanMaxAmountIdr: rInt(r, 'loan_max_amount_idr', 5000000),
    loanMinScore: rInt(r, 'loan_min_score', 60),
    loanTenors:
        (r['loan_tenors'] as List?)
            ?.whereType<num>()
            .map((n) => n.toInt())
            .toList() ??
        const [3, 6, 12],
    memberMonthlyQuotaKwh: rDbl(r, 'member_monthly_quota_kwh', 30),
    solarCostPerKwpIdr: rInt(r, 'solar_cost_per_kwp_idr', 15000000),
    arisanBankAccount: rStrN(r, 'arisan_bank_account'),
    createdAt: rDate(r, 'created_at'),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'name': name,
    'city': city,
    'invite_code': inviteCode,
    'created_by': createdBy,
    'loan_flat_monthly_rate_pct': loanFlatMonthlyRatePct,
    'loan_max_amount_idr': loanMaxAmountIdr,
    'loan_min_score': loanMinScore,
    'loan_tenors': loanTenors,
    'member_monthly_quota_kwh': memberMonthlyQuotaKwh,
    'solar_cost_per_kwp_idr': solarCostPerKwpIdr,
    'arisan_bank_account': arisanBankAccount,
    'created_at': ts(createdAt),
  };
}
