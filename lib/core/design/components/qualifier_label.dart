import 'package:flutter/material.dart';

import '../tokens.dart';

/// Honesty qualifier shown next to any `DEMO_SIMULATION` figure
/// (docs/DESIGN_SYSTEM.md §9, decision #10). Small neutral pill.
enum QualifierKind {
  estimasi('estimasi'),
  estimasiAwal('estimasi awal'),
  simulasi('simulasi'),
  ilustrasi('ilustrasi'),
  dataContoh('data contoh');

  const QualifierKind(this.label);
  final String label;
}

class QualifierLabel extends StatelessWidget {
  const QualifierLabel(this.kind, {super.key});

  final QualifierKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppRadius.pillBr,
      ),
      child: Text(
        kind.label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.primaryDark),
      ),
    );
  }
}
