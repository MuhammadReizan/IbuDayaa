import 'package:flutter/material.dart';

import '../../core/design/components/components.dart';
import '../../core/l10n/l10n.dart';

/// Full-screen scan analysis loading screen displayed after scanning a
/// bill or a demo barcode, before the result appears.
///
/// This is a rule-based lookup / computation, never a trained model — copy
/// here must never claim "AI".
class AnalysisLoadingScreen extends StatelessWidget {
  const AnalysisLoadingScreen({
    super.key,
    required this.onComplete,
    this.scenarioName,
  });

  final VoidCallback onComplete;
  final String? scenarioName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ScanLoadingScreen(
      badgeIcon: Icons.bolt_rounded,
      badgeLabel: scenarioName ?? l10n.scanAnalysisLoadingBadge,
      centerIcon: Icons.bolt_rounded,
      title: l10n.scanAnalysisLoadingSubtitle,
      steps: [
        l10n.scanStep1,
        l10n.scanStep2,
        l10n.scanStep3,
        l10n.scanStep4,
        l10n.scanStep5,
      ],
      onComplete: onComplete,
    );
  }
}
