import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/money.dart';
import '../application/financing_providers.dart';
import '../domain/financing_simulation.dart';

/// SC-10: Simulasi Pembiayaan (Input)
class FinancingInputScreen extends ConsumerStatefulWidget {
  const FinancingInputScreen({super.key});

  @override
  ConsumerState<FinancingInputScreen> createState() =>
      _FinancingInputScreenState();
}

class _FinancingInputScreenState extends ConsumerState<FinancingInputScreen> {
  double _amount = 500000;
  String _purpose = 'Bahan Produksi';
  int _tenor = 3;

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(loanParamsProvider);
    final ceiling = ref.watch(borrowingCeilingProvider);
    final TextTheme text = Theme.of(context).textTheme;

    // Constrain amount if ceiling is lower than current selection (or 0)
    if (_amount > ceiling && ceiling >= params.minIdr) {
      _amount = ceiling.toDouble();
    }

    final bool isEligible = ceiling > 0;

    return AppScaffold(
      title: 'Simulasi Pembiayaan',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Hitung Simulasi',
        onPressed: !isEligible
            ? null
            : () {
                final LoanSimulation simulation;
                try {
                  simulation = LoanSimulation.compute(
                    principalIdr: _amount.toInt(),
                    purpose: _purpose,
                    tenorMonths: _tenor,
                    params: params,
                  );
                } on LoanSimulationException catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.error.message)));
                  return;
                }
                context.push(AppRoute.financingResultPath, extra: simulation);
              },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isEligible) ...[
            const InfoBanner(
              tone: InfoTone.warning,
              icon: Icons.warning_amber_rounded,
              message:
                  'Skor kredit Anda belum memenuhi syarat untuk simulasi pembiayaan.',
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          Text('Pilih Nominal', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Text(
            formatRupiah(_amount.toInt()),
            style: text.headlineMedium?.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Slider(
            value: _amount,
            min: params.minIdr.toDouble(),
            max: ceiling > params.minIdr
                ? ceiling.toDouble()
                : params.minIdr.toDouble(),
            divisions: ceiling > params.minIdr
                ? (ceiling - params.minIdr) ~/ 100000
                : 1,
            onChanged: isEligible
                ? (val) {
                    setState(() => _amount = val);
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Tujuan Pembiayaan', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children:
                [
                  'Bahan Produksi',
                  'Alat Produksi',
                  'Renovasi Tempat',
                  'Lainnya',
                ].map((p) {
                  final selected = _purpose == p;
                  return ChoiceChip(
                    label: Text(p),
                    selected: selected,
                    onSelected: isEligible
                        ? (v) => setState(() => _purpose = p)
                        : null,
                  );
                }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Tenor', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [3, 6, 12].map((t) {
              final selected = _tenor == t;
              return ChoiceChip(
                label: Text('$t Bulan'),
                selected: selected,
                onSelected: isEligible
                    ? (v) => setState(() => _tenor = t)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
