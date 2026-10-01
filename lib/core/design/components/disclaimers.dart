import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'info_banner.dart';

/// Shown wherever a loan is discussed. The cooperative, not the app, lends —
/// and a person reviews every application.
class LoanDecisionNotice extends StatelessWidget {
  const LoanDecisionNotice({super.key});

  @override
  Widget build(BuildContext context) => InfoBanner(
    tone: InfoTone.info,
    message: AppLocalizations.of(context).loanDecisionNotice,
  );
}

/// Mandatory notice on the roof estimate. The result is an initial estimate
/// that needs on-site verification.
class VerificationNotice extends StatelessWidget {
  const VerificationNotice({super.key, this.text});

  /// Overrides the standard sentence when a screen needs its own wording.
  final String? text;

  @override
  Widget build(BuildContext context) => InfoBanner(
    tone: InfoTone.warning,
    message: text ?? AppLocalizations.of(context).verificationNotice,
  );
}
