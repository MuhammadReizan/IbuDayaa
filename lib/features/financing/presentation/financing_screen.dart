import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/app_data_controller.dart';
import '../../../core/data/derived_providers.dart';
import '../../../core/data/models.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';

/// A plain installment calculator for planning working capital.
///
/// IbuDaya is not a lender and has no lending partner, so this screen never
/// offers, applies for, or approves anything. What it does do is answer the
/// question a borrower actually needs answered before walking into a
/// cooperative or a bank: "what would the monthly payment be?"
class FinancingScreen extends ConsumerStatefulWidget {
  const FinancingScreen({super.key});

  @override
  ConsumerState<FinancingScreen> createState() => _FinancingScreenState();
}

class _FinancingScreenState extends ConsumerState<FinancingScreen> {
  static const _tenors = [3, 6, 12, 18, 24];

  final _principal = TextEditingController(text: '2000000');
  final _rate = TextEditingController(text: '2');
  int _tenor = 6;

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    super.dispose();
  }

  int? get _principalValue =>
      int.tryParse(_principal.text.trim().replaceAll(RegExp(r'[^0-9]'), ''));
  double? get _rateValue =>
      double.tryParse(_rate.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final p = _principalValue;
    final r = _rateValue;
    if (p == null || p <= 0 || r == null || r < 0) return;

    final controller = TextEditingController(
      text: 'Rencana ${formatRupiah(p)}',
    );
    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Simpan perhitungan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Beri nama'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (label == null || label.isEmpty) return;

    await ref
        .read(appDataProvider.notifier)
        .saveCalculation(
          label: label,
          principalIdr: p,
          tenorMonths: _tenor,
          monthlyRatePct: r,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perhitungan disimpan.')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final saved = ref.watch(savedCalculationsProvider);

    final p = _principalValue ?? 0;
    final r = _rateValue ?? 0;
    final totalCost = (p * (r / 100) * _tenor).round();
    final totalRepayment = p + totalCost;
    final monthly = _tenor == 0 ? 0 : (totalRepayment / _tenor).round();
    final bool valid = p > 0 && r >= 0;

    return AppScaffold(
      title: 'Hitung Cicilan',
      onBack: () => context.pop(),
      bottomBar: SecondaryButton(
        icon: Icons.bookmark_border_rounded,
        label: 'Simpan Perhitungan',
        onPressed: valid ? _save : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InfoBanner(
            tone: InfoTone.warning,
            title: 'IbuDaya bukan pemberi pinjaman',
            message:
                'Alat ini hanya menghitung. IbuDaya tidak menyalurkan, '
                'menawarkan, atau menyetujui pinjaman. Pakai hasilnya untuk '
                'membandingkan tawaran dari koperasi atau bank berizin OJK.',
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Jumlah pinjaman', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _principal,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(prefixText: 'Rp '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Bunga per bulan', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              suffixText: '% flat',
              helperText:
                  'Isi sesuai tawaran yang Anda terima. Bunga flat dihitung '
                  'dari pokok awal setiap bulan.',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Lama cicilan', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in _tenors)
                ChoiceChip(
                  label: Text('$t bulan'),
                  selected: _tenor == t,
                  onSelected: (_) => setState(() => _tenor = t),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          if (valid) ...[
            Container(
              padding: AppSpacing.hero,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: AppRadius.lgBr,
                boxShadow: AppShadows.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CICILAN PER BULAN',
                    style: text.labelSmall?.copyWith(
                      color: AppColors.textOnDarkDim,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    formatRupiah(monthly),
                    style: AppTypography.numeric(30, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'selama $_tenor bulan',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textOnDarkDim,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              child: Column(
                children: [
                  _Row(label: 'Pokok pinjaman', value: formatRupiah(p)),
                  const Divider(height: AppSpacing.lg),
                  _Row(label: 'Total bunga', value: formatRupiah(totalCost)),
                  const Divider(height: AppSpacing.lg),
                  _Row(
                    label: 'Total yang dikembalikan',
                    value: formatRupiah(totalRepayment),
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Rumusnya: bunga = pokok × ${r.toStringAsFixed(r % 1 == 0 ? 0 : 1)}% × '
              '$_tenor bulan. Cicilan = (pokok + bunga) ÷ $_tenor.',
              style: text.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),

          if (saved.isNotEmpty) ...[
            Text('Perhitungan Tersimpan', style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            for (int i = 0; i < saved.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _SavedRow(calc: saved[i]),
            ],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: text.bodyMedium?.copyWith(
              fontWeight: strong ? FontWeight.w700 : null,
              color: strong ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          textAlign: TextAlign.end,
          style: strong
              ? AppTypography.numeric(16, color: AppColors.primaryDark)
              : text.titleSmall,
        ),
      ],
    );
  }
}

class _SavedRow extends ConsumerWidget {
  const _SavedRow({required this.calc});
  final SavedCalculation calc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          FeatureBadge(
            icon: Icons.savings_outlined,
            tone: BadgeTone.mint,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  calc.label,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${calc.tenorMonths} bulan · '
                  '${calc.monthlyRatePct.toStringAsFixed(calc.monthlyRatePct % 1 == 0 ? 0 : 1)}%/bln · '
                  '${formatShortDate(calc.savedAt)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatRupiah(calc.monthlyInstallmentIdr),
            style: AppTypography.numeric(15, color: AppColors.primaryDark),
          ),
          IconButton(
            tooltip: 'Hapus',
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textTertiary,
            ),
            onPressed: () =>
                ref.read(appDataProvider.notifier).deleteCalculation(calc.id),
          ),
        ],
      ),
    );
  }
}
