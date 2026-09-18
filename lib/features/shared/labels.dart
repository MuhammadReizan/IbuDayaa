import 'package:flutter/material.dart';

import '../../core/design/components/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';

/// Appliance presets. Watts are typical ratings shown as a starting point; the
/// member corrects them from the label on her own appliance.
const Map<String, ({String label, IconData icon, double watts})>
kApplianceKinds = {
  'oven': (label: 'Oven', icon: Icons.microwave_rounded, watts: 1500),
  'refrigerator': (label: 'Kulkas', icon: Icons.kitchen_rounded, watts: 150),
  'sewingMachine': (
    label: 'Mesin Jahit',
    icon: Icons.content_cut_rounded,
    watts: 100,
  ),
  'blender': (label: 'Blender', icon: Icons.blender_rounded, watts: 350),
  'riceCooker': (
    label: 'Rice Cooker',
    icon: Icons.rice_bowl_rounded,
    watts: 400,
  ),
  'mixer': (label: 'Mixer', icon: Icons.cake_rounded, watts: 300),
  'iron': (label: 'Setrika', icon: Icons.iron_rounded, watts: 350),
  'fan': (label: 'Kipas Angin', icon: Icons.air_rounded, watts: 50),
  'other': (
    label: 'Lainnya',
    icon: Icons.electrical_services_rounded,
    watts: 100,
  ),
};

String applianceKindLabel(String kind, AppLocalizations l10n) => switch (kind) {
  'oven' => l10n.appliancePresetOven,
  'refrigerator' => l10n.appliancePresetKulkas,
  'sewingMachine' => l10n.appliancePresetMesinJahit,
  'blender' => l10n.appliancePresetBlender,
  'riceCooker' => l10n.appliancePresetRiceCooker,
  'mixer' => l10n.appliancePresetMixer,
  'iron' => l10n.appliancePresetSetrika,
  'fan' => l10n.appliancePresetKipasAngin,
  _ => l10n.appliancePresetLainnya,
};

IconData applianceIcon(String kind) =>
    (kApplianceKinds[kind] ?? kApplianceKinds['other']!).icon;

PillTone loanTone(LoanStatus s) => switch (s) {
  LoanStatus.submitted => PillTone.info,
  LoanStatus.inReview => PillTone.warning,
  LoanStatus.approved => PillTone.success,
  LoanStatus.disbursed => PillTone.success,
  LoanStatus.repaid => PillTone.neutral,
  LoanStatus.rejected => PillTone.danger,
  LoanStatus.cancelled => PillTone.neutral,
};

PillTone paymentTone(PaymentStatus s) => switch (s) {
  PaymentStatus.pending => PillTone.warning,
  PaymentStatus.confirmed => PillTone.success,
  PaymentStatus.rejected => PillTone.danger,
};

PillTone bookingTone(BookingStatus s) => switch (s) {
  BookingStatus.pendingVerification => PillTone.warning,
  BookingStatus.booked => PillTone.info,
  BookingStatus.completed => PillTone.success,
  BookingStatus.cancelled => PillTone.neutral,
};

String loanEventLabel(String type) => switch (type) {
  'submitted' => 'Pengajuan dikirim',
  'in_review' => 'Mulai direview admin',
  'approved' => 'Disetujui admin',
  'rejected' => 'Ditolak admin',
  'disbursed' => 'Dana dicairkan',
  'repaid' => 'Pinjaman lunas',
  'cancelled' => 'Pengajuan dibatalkan',
  'installment_paid' => 'Cicilan diterima',
  _ => type,
};

String localizedLoanEventLabel(
  String type,
  AppLocalizations l10n,
) => switch (type) {
  'submitted' => l10n.isEn ? 'Application submitted' : 'Pengajuan dikirim',
  'in_review' => l10n.isEn ? 'Review started by admin' : 'Mulai direview admin',
  'approved' => l10n.isEn ? 'Approved by admin' : 'Disetujui admin',
  'rejected' => l10n.isEn ? 'Rejected by admin' : 'Ditolak admin',
  'disbursed' => l10n.isEn ? 'Disbursed' : 'Dana dicairkan',
  'repaid' => l10n.isEn ? 'Loan repaid' : 'Pinjaman lunas',
  'cancelled' => l10n.isEn ? 'Application cancelled' : 'Pengajuan dibatalkan',
  'installment_paid' => l10n.isEn ? 'Installment received' : 'Cicilan diterima',
  _ => type,
};

IconData notificationIcon(String type) => switch (type) {
  'loan' => Icons.request_page_rounded,
  'payment' => Icons.payments_rounded,
  'quota' => Icons.swap_horiz_rounded,
  'booking' => Icons.solar_power_rounded,
  'announcement' => Icons.campaign_rounded,
  'member' => Icons.person_add_alt_1_rounded,
  'arisan' => Icons.groups_rounded,
  _ => Icons.notifications_rounded,
};
