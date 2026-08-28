import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/demo/demo_scenario.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/money.dart';
import '../application/arisan_providers.dart';

/// SC-08: Arisan Energi
class ArisanScreen extends ConsumerWidget {
  const ArisanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DemoArisanGroup group = ref.watch(arisanGroupProvider);
    final TextTheme text = Theme.of(context).textTheme;

    final isLunas = group.myContributionStatus.toLowerCase() == 'lunas';

    return AppScaffold(
      title: 'Arisan Energi',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        icon: Icons.handshake_outlined,
        label: 'Tukar & Bagikan Kuota',
        onPressed: () =>
            context.push(AppRoute.energyTradingPath), // to be added
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(group.name, style: text.titleMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isLunas
                            ? AppColors.successContainer
                            : AppColors.warningContainer,
                        borderRadius: AppRadius.pillBr,
                      ),
                      child: Text(
                        isLunas ? 'Lunas ✓' : group.myContributionStatus,
                        style: text.labelMedium?.copyWith(
                          color: isLunas
                              ? AppColors.primaryDark
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${group.members.length} Anggota',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Giliran Anda: ke-${group.myTurnPosition}',
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Jadwal Giliran (Bulan Ini)', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          // Rotation strip (top 3)
          ...group.rotation
              .take(3)
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SectionCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            r.memberName,
                            style: text.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${r.date.day}/${r.date.month}/${r.date.year}',
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.xl),

          Text('Catatan Transparan (Ledger)', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...group.ledger.map((entry) => _LedgerRow(entry: entry)),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final DemoLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    final IconData icon = switch (entry.type) {
      'contribution' => Icons.payments_outlined,
      'payout' => Icons.account_balance_wallet_outlined,
      'quotaShared' => Icons.arrow_outward_rounded,
      'quotaReceived' => Icons.arrow_downward_rounded,
      _ => Icons.receipt_long_outlined,
    };

    final Color iconColor = switch (entry.type) {
      'contribution' => AppColors.primary,
      'payout' => AppColors.success,
      'quotaShared' => AppColors.info,
      'quotaReceived' => AppColors.info,
      _ => AppColors.textSecondary,
    };

    String valueStr = '';
    if (entry.amountIdr != null) {
      valueStr = formatRupiah(entry.amountIdr!);
    } else if (entry.amountKwh != null) {
      valueStr = '${entry.amountKwh!.toStringAsFixed(1)} kWh';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SectionCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.memberName,
                        style: text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        valueStr,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatType(entry.type),
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${entry.note!}"',
                      style: text.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatType(String type) {
    return switch (type) {
      'contribution' => 'Pembayaran iuran',
      'payout' => 'Pencairan arisan',
      'quotaShared' => 'Membagikan kuota',
      'quotaReceived' => 'Menerima kuota',
      _ => type,
    };
  }
}
