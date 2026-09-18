import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/quota_insights.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';

/// Arisan Energi (virtual quota trading): members hand each other unused Solar
/// Hub quota. A trade completes the moment the second member answers — the
/// post was the first member's agreement — and moves no electricity.
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
    final incoming = data.incomingQuotaGifts(me.id);
    final active = data.activeOffers;

    final mineOpen = active
        .where(
          (o) =>
              o.ownerId == me.id &&
              (o.status == QuotaStatus.open || o.status == QuotaStatus.pending),
        )
        .toList();

    // Needs this member can fully fund, best fit first (rule shown below).
    final matches = quota.availableKwh < 0.5
        ? <QuotaMatch>[]
        : matchQuotaOffers(
            offers: active,
            myId: me.id,
            wantKind: QuotaKind.share,
            wantedKwh: quota.availableKwh,
            availableKwh: quota.availableKwh,
          ).take(3).toList();
    final matchedIds = matches.map((m) => m.offer.id).toSet();
    final market = active
        .where(
          (o) =>
              o.ownerId != me.id &&
              o.status == QuotaStatus.open &&
              !matchedIds.contains(o.id),
        )
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

    List<Widget> respond(QuotaOffer o) => [
      _action(
        context,
        ref,
        o.kind == QuotaKind.share
            ? l10n.arisanQuotaNeed
            : l10n.arisanQuotaShare,
        () => ref.read(actionsProvider).respondToQuota(o.id),
        confirm: l10n.quotaTradeConfirm(
          formatKwh(o.kwh),
          data.nameOf(o.ownerId),
        ),
        success: l10n.quotaTradedToast,
      ),
    ];

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
          if (incoming.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: l10n.quotaGiftIncomingTitle),
            for (final o in incoming) ...[
              _OfferCard(
                offer: o,
                headline: l10n.quotaGiftFrom(
                  data.nameOf(o.ownerId),
                  formatKwh(o.kwh),
                ),
                actions: [
                  _action(
                    context,
                    ref,
                    l10n.quotaGiftDecline,
                    secondary: true,
                    () => ref
                        .read(actionsProvider)
                        .answerQuotaGift(o.id, accept: false),
                    success: l10n.quotaGiftDeclinedToast,
                  ),
                  _action(
                    context,
                    ref,
                    l10n.quotaGiftAccept,
                    () => ref
                        .read(actionsProvider)
                        .answerQuotaGift(o.id, accept: true),
                    success: l10n.quotaGiftAcceptedToast,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: l10n.arisanQuotaShare,
                  onPressed: () => context.push('${Paths.quotaNew}?jenis=bagi'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SecondaryButton(
                  label: l10n.arisanQuotaNeed,
                  onPressed: () =>
                      context.push('${Paths.quotaNew}?jenis=butuh'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.arisanEnergyTradingSub, style: text.bodySmall),
          if (matches.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: l10n.quotaMatchTitle),
            for (final m in matches) ...[
              _OfferCard(
                offer: m.offer,
                headline:
                    '${data.nameOf(m.offer.ownerId)} (${l10n.arisanQuotaNeed})',
                reason: l10n.quotaMatchNeedFits(formatKwh(m.offer.kwh)),
                actions: respond(m.offer),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(l10n.quotaMatchRule, style: text.bodySmall),
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
                actions: respond(o),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          if (mineOpen.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: l10n.arisanQuotaNew),
            for (final o in mineOpen) ...[
              _OfferCard(
                offer: o,
                headline: o.status == QuotaStatus.pending
                    ? l10n.quotaGiftWaiting(data.nameOf(o.counterpartyId))
                    : o.kind == QuotaKind.share
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
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.quotaLedgerTitle),
          if (history.isEmpty)
            Text(l10n.quotaLedgerEmpty, style: text.bodyMedium)
          else
            for (final o in history)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TintedRow(
                  icon: o.giverId == me.id
                      ? Icons.north_east_rounded
                      : Icons.south_west_rounded,
                  tone: o.giverId == me.id ? PillTone.solar : PillTone.success,
                  title: o.giverId == me.id
                      ? '-${formatKwh(o.kwh)} · ${l10n.quotaLedgerGave(data.nameOf(o.receiverId))}'
                      : '+${formatKwh(o.kwh)} · ${l10n.quotaLedgerGot(data.nameOf(o.giverId))}',
                  subtitle: formatDateTime(o.updatedAt, l10n: l10n),
                ),
              ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.quotaLedgerNote, style: text.bodySmall),
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
          title: AppLocalizations.of(
            context,
          ).arisanQuotaActionConfirmTitle(label),
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
    this.reason,
  });

  final QuotaOffer offer;
  final String headline;
  final List<Widget> actions;

  /// Why this offer was suggested (shown under the headline).
  final String? reason;

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
                    if (reason != null)
                      Text(
                        reason!,
                        style: text.bodySmall?.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    Text(formatShortDate(o.createdAt), style: text.bodySmall),
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
