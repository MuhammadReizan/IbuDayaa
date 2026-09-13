import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../tokens.dart';

/// Honesty qualifier shown next to any `DEMO_SIMULATION` figure
/// (docs/DESIGN_SYSTEM.md §9). A small, neutral, dot-prefixed pill so a
/// simulated number never reads as a hard fact.
enum QualifierKind {
  estimasi('estimasi'),
  estimasiAwal('estimasi awal'),
  simulasi('simulasi'),
  ilustrasi('ilustrasi'),
  dataContoh('data contoh'),
  dataKomunitas('data komunitas');

  const QualifierKind(this.label);
  final String label;

  String localizedLabel(AppLocalizations l10n) => switch (this) {
    QualifierKind.estimasi => l10n.qualifierEstimasi,
    QualifierKind.estimasiAwal => l10n.qualifierEstimasiAwal,
    QualifierKind.simulasi => l10n.qualifierSimulasi,
    QualifierKind.ilustrasi => l10n.qualifierIlustrasi,
    QualifierKind.dataContoh => l10n.qualifierDataContoh,
    QualifierKind.dataKomunitas => l10n.qualifierDataKomunitas,
  };
}

class QualifierLabel extends StatelessWidget {
  const QualifierLabel(this.kind, {super.key, this.onDark = false});

  final QualifierKind kind;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Color fg = onDark ? AppColors.textOnDarkDim : AppColors.textSecondary;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.12)
            : AppColors.surfaceAlt,
        borderRadius: AppRadius.pillBr,
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.secondaryDark,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              kind.localizedLabel(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
