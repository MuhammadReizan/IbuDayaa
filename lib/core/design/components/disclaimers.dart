import 'package:flutter/material.dart';

import 'info_banner.dart';

/// Shown wherever a loan is discussed. The cooperative, not the app, lends —
/// and a person reviews every application.
class LoanDecisionNotice extends StatelessWidget {
  const LoanDecisionNotice({super.key});

  static const String text =
      'Keputusan pinjaman dibuat oleh admin koperasi Anda, bukan oleh '
      'aplikasi. Skor hanya membantu admin menilai.';

  @override
  Widget build(BuildContext context) =>
      const InfoBanner(tone: InfoTone.info, message: text);
}

/// Mandatory notice on the roof estimate. The result is an initial estimate
/// that needs on-site verification.
class VerificationNotice extends StatelessWidget {
  const VerificationNotice({super.key, this.text = _default});

  static const String _default =
      'Ini estimasi awal dari ukuran yang Anda masukkan. Teknisi tetap perlu '
      'memeriksa atap sebelum pemasangan.';

  final String text;

  @override
  Widget build(BuildContext context) =>
      InfoBanner(tone: InfoTone.warning, message: text);
}
