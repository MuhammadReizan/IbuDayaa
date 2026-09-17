import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/paths.dart';

/// Card "Scan QR Solar Panel" yang tampil di SolarHubScreen.
///
/// Mengarahkan pengguna ke [SolarQrScanScreen] untuk memindai QR demo
/// yang tertempel pada solar panel instalasi.
class SolarQrCard extends StatelessWidget {
  const SolarQrCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.smBr,
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.solarQrCardTitle,
                  style: text.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.solarQrCardSubtitle,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: l10n.solarQrCardAction,
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: () => context.push(Paths.solarQrScan),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
