import 'package:flutter/material.dart';

import 'info_banner.dart';

/// Fixed disclaimer for the financing simulation screens (decision #6 / CR-2).
/// The financing flow is a calculation only — no submission, no approval,
/// no disbursement.
class SimulationDisclaimer extends StatelessWidget {
  const SimulationDisclaimer({super.key});

  static const String text =
      'Ini simulasi, bukan penawaran resmi. IbuDaya tidak menyalurkan pinjaman.';

  @override
  Widget build(BuildContext context) =>
      const InfoBanner(tone: InfoTone.info, message: text);
}

/// Mandatory notice on the roof preliminary-assessment screen (decision #2 /
/// CR-13). The result is an initial estimate that needs on-site verification.
class VerificationNotice extends StatelessWidget {
  const VerificationNotice({super.key, this.text = _default});

  static const String _default =
      'Ini estimasi awal. Perlu verifikasi teknis di lokasi sebelum pemasangan.';

  final String text;

  @override
  Widget build(BuildContext context) =>
      InfoBanner(tone: InfoTone.warning, message: text);
}
