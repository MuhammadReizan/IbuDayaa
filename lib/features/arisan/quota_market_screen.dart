import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
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
    final l10n = AppLocalizations.of(context);
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
      title: l10n.arisanEnergyTrading,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.solarQuotaThisMonth} ${monthYearLabel(now, l10n: l10n)}',
                  style: text.labelLarge?.copyWith(
                    color: AppColors.textOnDarkDim,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatKwh(quota.availableKwh),
                  style: AppTypography.numeric(30, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: l10n.solarQuotaThisMonth,
                        value: formatKwh(quota.allocationKwh),
                        onDark: true,
                        valueSize: 15,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: l10n.scaffoldBookings,
                        value: formatKwh(quota.bookedKwh),
                        onDark: true,
                        valueSize: 15,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: l10n.arisanQuotaShare,
                        value: formatKwh(quota.givenKwh),
                        onDark: true,
                        valueSize: 15,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: l10n.arisanQuotaNeed,
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
                  label: l10n.arisanQuotaShare,
                  icon: Icons.volunteer_activism_rounded,
                  onPressed: () => context.push('${Paths.quotaNew}?jenis=bagi'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SecondaryButton(
                  label: l10n.arisanQuotaNeed,
                  icon: Icons.pan_tool_alt_rounded,
                  onPressed: () =>
                      context.push('${Paths.quotaNew}?jenis=butuh'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          InfoBanner(tone: InfoTone.info, message: l10n.arisanEnergyTradingSub),
          if (decide.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: l10n.labelPending),
            for (final o in decide) ...[
              _OfferCard(
                offer: o,
                headline: o.kind == QuotaKind.share
                    ? '${data.nameOf(o.counterpartyId)} (${l10n.arisanQuotaNeed})'
                    : '${data.nameOf(o.counterpartyId)} (${l10n.arisanQuotaShare})',
                actions: [
                  _action(
                    context,
                    ref,
                    l10n.actionCancel,
                    secondary: true,
                    () => ref
                        .read(actionsProvider)
                        .settleQuota(o.id, accept: false),
                  ),
                  _action(
                    context,
                    ref,
                    l10n.actionConfirm,
                    () => ref
                        .read(actionsProvider)
                        .settleQuota(o.id, accept: true),
                    success: l10n.arisanQuotaUpdatedToast,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          if (waiting.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: l10n.labelPending),
            for (final o in waiting) ...[
              _OfferCard(
                offer: o,
                headline: '${l10n.labelPending} ${data.nameOf(o.ownerId)}',
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.arisanQuotaTitle),
          if (market.isEmpty)
            SectionCard(
              child: Row(
                children: [
                  const BrandArt(motif: BrandArtMotif.arisan, size: 56),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(l10n.arisanQuotaEmpty, style: text.bodyMedium),
                  ),
                ],
              ),
            )
          else
            for (final o in market) ...[
              _OfferCard(
                offer: o,
                headline: o.kind == QuotaKind.share
                    ? '${data.nameOf(o.ownerId)} (${l10n.arisanQuotaShare})'
                    : '${data.nameOf(o.ownerId)} (${l10n.arisanQuotaNeed})',
                actions: [
                  _action(
                    context,
                    ref,
                    o.kind == QuotaKind.share
                        ? l10n.arisanQuotaNeed
                        : l10n.arisanQuotaShare,
                    () => ref.read(actionsProvider).respondToQuota(o.id),
                    confirm: o.kind == QuotaKind.need
                        ? '${formatKwh(o.kwh)} (${data.nameOf(o.ownerId)})'
                        : null,
                    success: l10n.arisanQuotaSentToast,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          if (mineOpen.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: l10n.arisanQuotaNew),
            for (final o in mineOpen) ...[
              _OfferCard(
                offer: o,
                headline: o.kind == QuotaKind.share
                    ? l10n.arisanQuotaShare
                    : l10n.arisanQuotaNeed,
                actions: [
                  _action(
                    context,
                    ref,
                    l10n.actionCancel,
                    secondary: true,
                    () => ref.read(actionsProvider).cancelQuota(o.id),
                    confirm: l10n.actionCancel,
                    destructive: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: l10n.arisanHistory),
            for (final o in history.take(10))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TintedRow(
                  icon: o.giverId == me.id
                      ? Icons.north_east_rounded
                      : Icons.south_west_rounded,
                  tone: o.giverId == me.id ? PillTone.solar : PillTone.success,
                  title: o.giverId == me.id
                      ? '${formatKwh(o.kwh)} → ${data.nameOf(o.receiverId)}'
                      : '${formatKwh(o.kwh)} ← ${data.nameOf(o.giverId)}',
                  subtitle: formatShortDate(o.updatedAt, l10n: l10n),
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
    bool destructive = false,
  }) {
    Future<void> go() async {
      if (confirm != null) {
        final ok = await confirmDialog(
          context,
          title: AppLocalizations.of(context).arisanQuotaActionConfirmTitle(label),
          message: confirm,
          confirmLabel: label,
          destructive: destructive,
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
