import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/money.dart';
import '../domain/financing_simulation.dart';

/// SC-11: Hasil Simulasi Pembiayaan
class FinancingResultScreen extends StatelessWidget {
  const FinancingResultScreen({super.key, required this.simulation});

  final LoanSimulation simulation;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Hasil Simulasi',
      onBack: () => context.pop(),
      // No optional secondary CTA requested in P0 ("Preferred P0: omit it").
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InfoBanner(
            tone: InfoTone.info,
            icon: Icons.info_outline,
            message: 'Simulasi, bukan penawaran resmi.',
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            title: 'Estimasi Cicilan',
            child: Column(
              children: [
                Text(
                  formatRupiah(simulation.monthlyInstallmentIdr),
                  style: text.headlineMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'per bulan selama ${simulation.tenorMonths} bulan',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'Rincian Simulasi',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailRow(label: 'Tujuan', value: simulation.purpose),
                const Divider(height: AppSpacing.xl),
                _DetailRow(
                  label: 'Nominal Pembiayaan',
                  value: formatRupiah(simulation.principalIdr),
                ),
                const Divider(height: AppSpacing.xl),
                _DetailRow(
                  label: 'Tenor',
                  value: '${simulation.tenorMonths} Bulan',
                ),
                const Divider(height: AppSpacing.xl),
                _DetailRow(
                  label: 'Estimasi Bagi Hasil (Flat)',
                  value:
                      '${simulation.flatMonthlyRatePct.toStringAsFixed(1)}% per bulan',
                ),
                const Divider(height: AppSpacing.xl),
                _DetailRow(
                  label: 'Estimasi Total Biaya',
                  value: formatRupiah(simulation.totalCostIdr),
                ),
                const Divider(height: AppSpacing.xl),
                _DetailRow(
                  label: 'Estimasi Total Pengembalian',
                  value: formatRupiah(simulation.totalRepaymentIdr),
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: text.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.w600 : null,
          ),
        ),
        Text(
          value,
          style: text.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
