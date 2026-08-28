import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/demo/demo_scenario.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../application/arisan_providers.dart';
import 'take_offer_sheet.dart';

/// SC-12: Bursa Kuota / Energy Trading
class EnergyTradingScreen extends ConsumerWidget {
  const EnergyTradingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DemoEnergyQuota quota = ref.watch(energyQuotaProvider);
    final List<DemoQuotaOffer> offers = ref.watch(quotaOffersProvider);
    final TextTheme text = Theme.of(context).textTheme;

    final openOffers = offers.where((o) => o.status == 'open').toList();

    return AppScaffold(
      title: 'Bursa Kuota',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        icon: Icons.add_circle_outline,
        label: 'Bagikan Kuota Saya',
        onPressed: quota.availableKwh <= 0
            ? null
            : () => context.push(AppRoute.shareQuotaPath),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Kebutuhan Kuota Saya',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kuota dibutuhkan', style: text.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${quota.neededKwh.toStringAsFixed(1)} kWh',
                      style: text.headlineSmall?.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                if (quota.neededKwh > 0)
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    size: 32,
                  )
                else
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 32,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Penawaran dari Komunitas', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (openOffers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('Belum ada penawaran aktif di komunitas Anda.'),
              ),
            )
          else
            ...openOffers.map(
              (o) => _OfferTile(offer: o, neededKwh: quota.neededKwh),
            ),
        ],
      ),
    );
  }
}

class _OfferTile extends ConsumerWidget {
  const _OfferTile({required this.offer, required this.neededKwh});

  final DemoQuotaOffer offer;
  final double neededKwh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SectionCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(offer.ownerName, style: text.titleSmall),
                Text(
                  '${offer.amountKwh.toStringAsFixed(1)} kWh',
                  style: text.titleMedium?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  offer.slotLabel,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (offer.note != null && offer.note!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '"${offer.note!}"',
                style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Ambil Kuota',
              onPressed: neededKwh <= 0
                  ? null
                  : () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => TakeOfferSheet(offer: offer),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
