import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/data/app_data_controller.dart';
import '../../../core/data/derived_providers.dart';
import '../../../core/data/models.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/energy.dart';
import '../../../core/format/money.dart';

IconData applianceIcon(String kind) => switch (kind) {
  'oven' => Icons.microwave_outlined,
  'sewingMachine' => Icons.content_cut_outlined,
  'refrigerator' => Icons.kitchen_outlined,
  'blender' => Icons.blender_outlined,
  _ => Icons.electrical_services_outlined,
};

/// The user's declared equipment. Cost attribution is only as good as this
/// list, so the screen keeps the running total visible.
class AppliancesScreen extends ConsumerWidget {
  const AppliancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appliances = ref.watch(appliancesProvider);
    final tariff = ref.watch(profileProvider)?.tariffIdrPerKwh ?? 0;
    final text = Theme.of(context).textTheme;

    final totalKwh = appliances.fold<double>(0, (s, a) => s + a.monthlyKwh);
    final totalCost = (totalKwh * tariff).round();

    return AppScaffold(
      title: 'Alat Usaha',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        icon: Icons.add_rounded,
        label: 'Tambah Alat',
        onPressed: () => context.push(AppRoute.applianceEditPath),
      ),
      body: appliances.isEmpty
          ? EmptyState(
              motif: BrandArtMotif.solar,
              title: 'Belum ada alat',
              message:
                  'Daftarkan alat usaha Anda beserta daya dan jam pakainya. '
                  'IbuDaya akan memecah tagihan listrik Anda per alat.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  tone: CardTone.mint,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Perkiraan pemakaian bulanan',
                              style: text.titleSmall?.copyWith(
                                color: AppColors.primaryDarker,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dari ${appliances.length} alat yang Anda catat',
                              style: text.bodySmall?.copyWith(
                                color: AppColors.primaryDarker,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatKwh(totalKwh),
                            style: AppTypography.numeric(
                              18,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            '≈ ${formatRupiah(totalCost)}',
                            style: text.labelSmall?.copyWith(
                              color: AppColors.primaryDarker,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                for (int i = 0; i < appliances.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _ApplianceRow(appliance: appliances[i], tariff: tariff),
                ],
              ],
            ),
    );
  }
}

class _ApplianceRow extends ConsumerWidget {
  const _ApplianceRow({required this.appliance, required this.tariff});

  final Appliance appliance;
  final double tariff;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus alat?'),
        content: Text('${appliance.name} akan dihapus dari daftar Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(appDataProvider.notifier).deleteAppliance(appliance.id);
    messenger.showSnackBar(const SnackBar(content: Text('Alat dihapus.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push(AppRoute.applianceEditPath, extra: appliance),
      child: Row(
        children: [
          FeatureBadge(
            icon: applianceIcon(appliance.kind),
            tone: BadgeTone.solar,
            size: 42,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appliance.name,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${appliance.watts.round()} W · '
                  '${appliance.hoursPerDay} jam/hari · '
                  '${appliance.daysPerWeek} hari/minggu',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(appliance.monthlyCostIdr(tariff)),
                style: AppTypography.numeric(15, color: AppColors.textPrimary),
              ),
              Text('per bulan', style: text.labelSmall),
            ],
          ),
          IconButton(
            tooltip: 'Hapus',
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textTertiary,
            ),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }
}
