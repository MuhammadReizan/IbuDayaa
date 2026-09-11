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
import '../../../core/format/dates.dart';
import '../../../core/format/energy.dart';
import '../../../core/format/money.dart';

/// Every electricity bill the user has recorded. This list is the foundation
/// every other number in the app is computed from.
class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider);
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Tagihan Listrik',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        icon: Icons.add_rounded,
        label: 'Catat Tagihan',
        onPressed: () => context.push(AppRoute.billAddPath),
      ),
      body: bills.isEmpty
          ? EmptyState(
              motif: BrandArtMotif.scan,
              title: 'Belum ada tagihan',
              message:
                  'Catat tagihan PLN bulanan Anda. Setelah 3 bulan, IbuDaya '
                  'bisa menghitung skor dan menganalisis pemakaian Anda.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${bills.length} tagihan tercatat', style: text.bodySmall),
                const SizedBox(height: AppSpacing.md),
                for (int i = 0; i < bills.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _BillRow(
                    bill: bills[i],
                    previous: i + 1 < bills.length ? bills[i + 1] : null,
                  ),
                ],
              ],
            ),
    );
  }
}

class _BillRow extends ConsumerWidget {
  const _BillRow({required this.bill, this.previous});

  final Bill bill;
  final Bill? previous;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus tagihan?'),
        content: Text(
          'Tagihan ${formatMonthYear(bill.periodMonth)} akan dihapus. '
          'Skor dan analisis Anda ikut berubah.',
        ),
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
    await ref.read(appDataProvider.notifier).deleteBill(bill.id);
    messenger.showSnackBar(const SnackBar(content: Text('Tagihan dihapus.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final prev = previous;
    final double? change = (prev == null || prev.kwh <= 0)
        ? null
        : (bill.kwh - prev.kwh) / prev.kwh * 100;

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push(AppRoute.billAddPath, extra: bill),
      child: Row(
        children: [
          FeatureBadge(
            icon: Icons.receipt_long_outlined,
            tone: BadgeTone.mint,
            size: 42,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatMonthYear(bill.periodMonth),
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(formatKwh(bill.kwh), style: text.bodySmall),
                    if (change != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        change >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color: change >= 0
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                      Text(
                        '${change.abs().round()}%',
                        style: text.labelSmall?.copyWith(
                          color: change >= 0
                              ? AppColors.danger
                              : AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(bill.totalIdr),
                style: AppTypography.numeric(15, color: AppColors.textPrimary),
              ),
              Text(
                '${formatRupiah(bill.idrPerKwh.round())}/kWh',
                style: text.labelSmall,
              ),
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
