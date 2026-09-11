import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';

/// Perdagangan Energi: members hand each other unused Solar Hub quota.
class QuotaMarketScreen extends ConsumerWidget {
  const QuotaMarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;
    final quota = data.quotaOf(me.id, now);
    final active = data.activeOffers;

    final decide = active
        .where((o) => o.ownerId == me.id && o.status == QuotaStatus.pending)
        .toList();
    final mineOpen = active
        .where((o) => o.ownerId == me.id && o.status == QuotaStatus.open)
        .toList();
    final waiting = active
        .where(
          (o) => o.counterpartyId == me.id && o.status == QuotaStatus.pending,
        )
        .toList();
    final market = active
        .where((o) => o.ownerId != me.id && o.status == QuotaStatus.open)
        .toList();
    final history =
        data.offers
            .where(
              (o) =>
                  o.status == QuotaStatus.completed &&
                  (o.ownerId == me.id || o.counterpartyId == me.id),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return AppScaffold(
      title: 'Perdagangan Energi',
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kuota Solar Hub ${monthYearLabel(now)}',
                  style: text.labelLarge?.copyWith(
                    color: AppColors.textOnDarkDim,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${formatKwh(quota.availableKwh)} tersisa',
                  style: AppTypography.numeric(30, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Jatah',
                        value: formatKwh(quota.allocationKwh),
                        onDark: true,
                        valueSize: 15,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: 'Dibooking',
                        value: formatKwh(quota.bookedKwh),
                        onDark: true,
                        valueSize: 15,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: 'Diberi',
                        value: formatKwh(quota.givenKwh),
                        onDark: true,
                        valueSize: 15,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: 'Diterima',
                        value: formatKwh(quota.receivedKwh),
                        onDark: true,
                        valueSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Bagikan',
                  icon: Icons.volunteer_activism_rounded,
                  onPressed: () => context.push('${Paths.quotaNew}?jenis=bagi'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SecondaryButton(
                  label: 'Butuh kuota',
                  icon: Icons.pan_tool_alt_rounded,
                  onPressed: () =>
                      context.push('${Paths.quotaNew}?jenis=butuh'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const InfoBanner(
            tone: InfoTone.info,
            message:
                'Tukar kuota hanya mencatat kesepakatan jatah booking hub antar '
                'anggota. Tidak ada listrik yang dikirim lewat aplikasi.',
          ),
          if (decide.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Perlu keputusan Anda'),
            for (final o in decide) ...[
              _OfferCard(
                offer: o,
                headline: o.kind == QuotaKind.share
                    ? '${data.nameOf(o.counterpartyId)} meminta kuota Anda'
                    : '${data.nameOf(o.counterpartyId)} ingin memberi kuota',
                actions: [
                  _action(
                    context,
                    ref,
                    'Tolak',
                    secondary: true,
                    () => ref
                        .read(actionsProvider)
                        .settleQuota(o.id, accept: false),
                  ),
                  _action(
                    context,
                    ref,
                    'Terima',
                    () => ref
                        .read(actionsProvider)
                        .settleQuota(o.id, accept: true),
                    success: 'Pertukaran kuota tercatat.',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          if (waiting.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Menunggu jawaban'),
            for (final o in waiting) ...[
              _OfferCard(
                offer: o,
                headline: 'Menunggu ${data.nameOf(o.ownerId)} menerima',
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Penawaran anggota'),
          if (market.isEmpty)
            SectionCard(
              child: Row(
                children: [
                  const BrandArt(motif: BrandArtMotif.arisan, size: 56),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Belum ada penawaran dari anggota lain.',
                      style: text.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final o in market) ...[
              _OfferCard(
                offer: o,
                headline: o.kind == QuotaKind.share
                    ? '${data.nameOf(o.ownerId)} membagikan kuota'
                    : '${data.nameOf(o.ownerId)} butuh kuota',
                actions: [
                  _action(
                    context,
                    ref,
                    o.kind == QuotaKind.share ? 'Minta' : 'Beri',
                    () => ref.read(actionsProvider).respondToQuota(o.id),
                    confirm: o.kind == QuotaKind.need
                        ? 'Kuota Anda akan berkurang ${formatKwh(o.kwh)} jika '
                              '${data.nameOf(o.ownerId)} menerima. Sisa kuota Anda '
                              'sekarang ${formatKwh(quota.availableKwh)}.'
                        : null,
                    success:
                        'Terkirim. Menunggu ${data.nameOf(o.ownerId)} menerima.',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          if (mineOpen.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Penawaran saya'),
            for (final o in mineOpen) ...[
              _OfferCard(
                offer: o,
                headline: o.kind == QuotaKind.share
                    ? 'Anda membagikan kuota'
                    : 'Anda butuh kuota',
                actions: [
                  _action(
                    context,
                    ref,
                    'Batalkan',
                    secondary: true,
                    () => ref.read(actionsProvider).cancelQuota(o.id),
                    confirm: 'Penawaran ini akan ditutup.',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Riwayat'),
            for (final o in history.take(10))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TintedRow(
                  icon: o.giverId == me.id
                      ? Icons.north_east_rounded
                      : Icons.south_west_rounded,
                  tone: o.giverId == me.id ? PillTone.solar : PillTone.success,
                  title: o.giverId == me.id
                      ? 'Memberi ${formatKwh(o.kwh)} ke ${data.nameOf(o.receiverId)}'
                      : 'Menerima ${formatKwh(o.kwh)} dari ${data.nameOf(o.giverId)}',
                  subtitle: formatShortDate(o.updatedAt),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    WidgetRef ref,
    String label,
    Future<void> Function() run, {
    bool secondary = false,
    String? confirm,
    String? success,
  }) {
    Future<void> go() async {
      if (confirm != null) {
        final ok = await confirmDialog(
          context,
          title: '$label kuota?',
          message: confirm,
          confirmLabel: label,
          destructive: label == 'Batalkan',
        );
        if (!ok || !context.mounted) return;
      }
      await runAction(context, run, success: success);
    }

    return secondary
        ? SecondaryButton(label: label, onPressed: go)
        : PrimaryButton(label: label, onPressed: go);
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.headline,
    this.actions = const [],
  });

  final QuotaOffer offer;
  final String headline;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final o = offer;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FeatureBadge(
                icon: o.kind == QuotaKind.share
                    ? Icons.volunteer_activism_rounded
                    : Icons.pan_tool_alt_rounded,
                tone: o.kind == QuotaKind.share
                    ? BadgeTone.mint
                    : BadgeTone.solar,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: text.titleSmall),
                    Text(
                      [
                        if (o.slotNote.isNotEmpty) o.slotNote,
                        formatShortDate(o.createdAt),
                      ].join(' · '),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(formatKwh(o.kwh), style: AppTypography.numeric(18)),
            ],
          ),
          if (o.note != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '"${o.note}"',
              style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
