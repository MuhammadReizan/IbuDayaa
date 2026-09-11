import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/brand/brand.dart';
import '../../../core/data/app_data_controller.dart';
import '../../../core/data/derived_providers.dart';
import '../../../core/data/models.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/energy.dart';

/// Quota the user offered to their circle, and what became of it.
///
/// Nothing here moves electricity. It is a written agreement — "you can use my
/// slot on Saturday" — kept where both sides can point at it later.
class QuotaTradingScreen extends ConsumerWidget {
  const QuotaTradingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(offersProvider);
    final group = ref.watch(arisanProvider);
    final openKwh = ref.watch(openOfferKwhProvider);
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Berbagi Kuota',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        icon: Icons.volunteer_activism_outlined,
        label: 'Tawarkan Kuota',
        onPressed: group == null
            ? null
            : () => context.push(AppRoute.quotaSharePath),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (group == null) ...[
            const InfoBanner(
              tone: InfoTone.warning,
              title: 'Buat grup arisan dulu',
              message:
                  'Berbagi kuota dicatat di dalam grup arisan Anda, supaya '
                  'semua anggota bisa melihat riwayatnya.',
            ),
            const SizedBox(height: AppSpacing.xl),
          ] else ...[
            SectionCard(
              leadingIcon: Icons.bolt_rounded,
              title: 'Kuota yang Anda tawarkan',
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatKwh(openKwh),
                          style: AppTypography.numeric(
                            24,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text('Masih terbuka', style: text.bodySmall),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 34, color: AppColors.outline),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${offers.where((o) => o.status == 'taken').length}',
                          style: AppTypography.numeric(
                            24,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text('Sudah diambil', style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          Text('Riwayat Penawaran', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),

          if (offers.isEmpty)
            const EmptyState(
              motif: BrandArtMotif.community,
              title: 'Belum ada penawaran',
              message:
                  'Kalau ada sisa kuota di giliran Anda, tawarkan ke anggota '
                  'lain supaya tidak terbuang.',
            )
          else
            for (int i = 0; i < offers.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _OfferCard(offer: offers[i], group: group),
            ],

          const SizedBox(height: AppSpacing.lg),
          const InfoBanner(
            tone: InfoTone.info,
            message:
                'Catatan ini adalah kesepakatan antaranggota, bukan pemindahan '
                'listrik. Pemakaian sebenarnya tetap diatur di Solar Hub.',
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends ConsumerWidget {
  const _OfferCard({required this.offer, required this.group});

  final QuotaOffer offer;
  final ArisanGroup? group;

  Future<void> _markTaken(BuildContext context, WidgetRef ref) async {
    final members = (group?.members ?? const <ArisanMember>[])
        .where((m) => !m.isMe)
        .toList();

    final name = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Siapa yang mengambil kuota ini?',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('Belum ada anggota lain di grup Anda.'),
              )
            else
              for (final m in members)
                ListTile(
                  leading: MemberAvatar(name: m.name, size: 34),
                  title: Text(m.name),
                  onTap: () => Navigator.of(sheetContext).pop(m.name),
                ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (name == null) return;
    await ref.read(appDataProvider.notifier).markOfferTaken(offer.id, name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final isOpen = offer.status == 'open';

    return Opacity(
      opacity: isOpen ? 1 : 0.65,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FeatureBadge(
                  icon: Icons.volunteer_activism_outlined,
                  tone: BadgeTone.sky,
                  size: 40,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.slotLabel,
                        style: text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        offer.status == 'taken'
                            ? 'Diambil ${offer.takenByName ?? "anggota"}'
                            : offer.status == 'cancelled'
                            ? 'Dibatalkan'
                            : 'Ditawarkan ${formatShortDate(offer.createdAt)}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppRadius.pillBr,
                  ),
                  child: Text(
                    formatKwh(offer.amountKwh),
                    style: AppTypography.numeric(
                      15,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            if (offer.note != null && offer.note!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '“${offer.note!}”',
                style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            if (isOpen) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Tandai Diambil',
                      onPressed: () => _markTaken(context, ref),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: 'Batalkan',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => ref
                        .read(appDataProvider.notifier)
                        .cancelOffer(offer.id),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
