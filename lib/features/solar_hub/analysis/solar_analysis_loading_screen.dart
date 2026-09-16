import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/components.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/paths.dart';
import '../../../core/solar_demo/solar_panel_model.dart';
import 'solar_panel_result_screen.dart';

/// Loading screen shown for 2-3 seconds after a solar-panel QR code is
/// scanned, before [SolarPanelResultScreen] appears.
///
/// If [panelData] is null (should not happen in the normal flow), the screen
/// still plays out its animation and then pops.
class SolarAnalysisLoadingScreen extends StatelessWidget {
  const SolarAnalysisLoadingScreen({super.key, required this.panelData});

  final SolarPanelData? panelData;

  void _onComplete(BuildContext context) {
    final data = panelData;
    if (data != null) {
      context.pushReplacement(Paths.solarQrResult, extra: data);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ScanLoadingScreen(
      badgeIcon: Icons.solar_power_rounded,
      badgeLabel: l10n.solarScanBadge,
      centerIcon: Icons.solar_power_rounded,
      title: l10n.solarScanTitle,
      steps: [
        l10n.solarScanStep1,
        l10n.solarScanStep2,
        l10n.solarScanStep3,
        l10n.solarScanStep4,
        l10n.solarScanStep5,
      ],
      stepDuration: const Duration(milliseconds: 500),
      completionDelay: const Duration(milliseconds: 300),
      onComplete: () => _onComplete(context),
    );
  }
}
