import 'package:flutter/material.dart';

import '../../core/design/components/ui_kit.dart';
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
