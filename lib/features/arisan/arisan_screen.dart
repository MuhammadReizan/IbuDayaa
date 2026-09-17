import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/db/row.dart';
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
import '../shared/labels.dart';

class ArisanScreen extends ConsumerStatefulWidget {
  const ArisanScreen({super.key});

  @override
  ConsumerState<ArisanScreen> createState() => _ArisanScreenState();
}

class _ArisanScreenState extends ConsumerState<ArisanScreen> {
  String? _groupId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final groups = data.groupsOf(me.id);

    if (groups.isEmpty) {
      final support = data.supportThreadOf(me.id);
      return AppScaffold(
        title: l10n.arisanTitle,
        onBack: () => context.pop(),
        scrollable: false,
        body: EmptyState(
          motif: BrandArtMotif.arisan,
          title: 'Anda belum ikut arisan',
          message:
              'Grup arisan dibuat oleh admin koperasi. Minta admin memasukkan '
              'Anda ke grup.',
          action: support == null
              ? null
              : SecondaryButton(
                  label: 'Kirim pesan ke admin',
                  expand: false,
                  onPressed: () => context.push(Paths.thread(support.id)),
                ),
        ),
      );
    }

    final g = groups.firstWhere(
      (x) => x.id == _groupId,
      orElse: () => groups.first,
    );
    final members = data.membersOfGroup(g.id);
    final pot = g.contributionIdr * members.length;
    final recipient = data.recipientFor(g, now);
    final myTurn = data.turnMonthOf(g, me.id);
    final mine = data.contributionFor(g.id, me.id, now);
    final rejected = data
        .paymentsOfGroup(g.id)
        .where(
          (p) =>
              p.userId == me.id &&
              p.type == PaymentType.contribution &&
              p.status == PaymentStatus.rejected &&
              sameMonth(p.periodMonth, now),
        )
        .firstOrNull;
    final payout = data
        .paymentsOfGroup(g.id)
        .where(
          (p) => p.type == PaymentType.payout && sameMonth(p.periodMonth, now),
        )
        .firstOrNull;
    final history = data
        .paymentsOfGroup(g.id)
        .where((p) => p.userId == me.id)
        .toList();
    final groupThread = data.groupThreadOf(g.id);
    final started = !monthOf(now).isBefore(g.startMonth);

    return AppScaffold(
      title: l10n.arisanTitle,
      onBack: () => context.pop(),
      actions: [
        if (groupThread != null)
          IconButton(
            tooltip: l10n.arisanGroupChat,
            onPressed: () => context.push(Paths.thread(groupThread.id)),
            icon: const Icon(Icons.forum_outlined),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (groups.length > 1) ...[
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final x in groups)
                  ChoiceChip(
                    label: Text(x.name),
                    selected: x.id == g.id,
                    onSelected: (_) => setState(() => _groupId = x.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.name,
                  style: text.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.arisanTotalPerMonth,
                  style: text.labelMedium?.copyWith(
                    color: AppColors.textOnDarkDim,
                  ),
                ),
                Text(
                  formatRupiah(pot),
                  style: AppTypography.numeric(30, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: l10n.arisanDuesLabel,
                        value: formatRupiah(g.contributionIdr),
                        onDark: true,
                        valueSize: 16,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: l10n.arisanTurnThisMonth,
                        value: started ? data.nameOf(recipient?.userId) : '-',
                        onDark: true,
                        valueSize: 16,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: l10n.arisanYourTurn,
                        value: shortMonthYear(myTurn, l10n: l10n),
                        onDark: true,
                        valueSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: '${l10n.arisanDuesLabel} ${monthYearLabel(now, l10n: l10n)}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!started)
                  Text(
                    l10n.arisanStartsMonth(
                      monthYearLabel(g.startMonth, l10n: l10n),
                    ),
                    style: text.bodyMedium,
                  )
                else if (mine == null) ...[
                  if (rejected != null) ...[
                    InfoBanner(
                      tone: InfoTone.danger,
                      title: l10n.arisanPrevRejected,
                      message: rejected.note ?? l10n.arisanPrevRejectedNote,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(() {
                    final bank = data.cooperative?.arisanBankAccount;
                    final amount = formatRupiah(g.contributionIdr);
                    return (bank == null || bank.trim().isEmpty)
                        ? l10n.arisanPayInstruction(amount)
                        : l10n.arisanPayInstructionWithBank(
                            amount,
                            bank.trim(),
                          );
                  }(), style: text.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: l10n.arisanPaidBtn,
                    icon: Icons.payments_rounded,
                    loading: _busy,
                    onPressed: () => _pay(g, l10n),
                  ),
                ] else
                  Row(
                    children: [
                      Icon(
                        mine.status == PaymentStatus.confirmed
                            ? Icons.verified_rounded
                            : Icons.hourglass_top_rounded,
                        color: mine.status == PaymentStatus.confirmed
                            ? AppColors.primary
                            : AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          mine.status == PaymentStatus.confirmed
                              ? l10n.arisanPaidSuccess
                              : l10n.arisanPaidPending,
                          style: text.bodyMedium,
                        ),
                      ),
                      StatusPill(
                        label: mine.status.localizedLabel(l10n),
                        tone: paymentTone(mine.status),
                      ),
                    ],
                  ),
                if (payout != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  InfoBanner(
                    tone: InfoTone.success,
                    message: l10n.arisanPayoutInfo(
                      data.nameOf(payout.userId),
                      formatRupiah(payout.amountIdr),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            onTap: () => context.push(Paths.quota),
            tone: CardTone.solar,
            child: Row(
              children: [
                const FeatureBadge(
                  icon: Icons.swap_horiz_rounded,
                  tone: BadgeTone.solar,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.arisanEnergyTrading, style: text.titleMedium),
                      Text(
                        l10n.arisanEnergyTradingSub,
                        style: text.bodySmall?.copyWith(
                          color: AppColors.onSolar,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.arisanMembersCount(members.length)),
          for (final m in members) ...[
            _MemberRow(
              name: data.nameOf(m.userId),
              turn: m.turnOrder,
              turnMonth: DateTime(
                g.startMonth.year,
                g.startMonth.month + m.turnOrder - 1,
              ),
              isMe: m.userId == me.id,
              isRecipient: started && recipient?.userId == m.userId,
              payment: data.contributionFor(g.id, m.userId, now),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: l10n.arisanMyHistory),
            SectionCard(
              child: Column(
                children: [
                  for (final p in history.take(12))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p.type.localizedLabel(l10n)} · ${monthYearLabel(p.periodMonth, l10n: l10n)}',
                                  style: text.titleSmall,
                                ),
                                Text(
                                  formatRupiah(p.amountIdr),
                                  style: text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          StatusPill(
                            label: p.status.localizedLabel(l10n),
                            tone: paymentTone(p.status),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pay(ArisanGroup g, AppLocalizations l10n) async {
    final ok = await confirmDialog(
      context,
      title: l10n.arisanPayConfirmTitle,
      message: l10n.arisanPayConfirmMsg(formatRupiah(g.contributionIdr)),
      confirmLabel: l10n.actionSend,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await runAction(
      context,
      () => ref.read(actionsProvider).submitContribution(g.id),
      success: l10n.arisanPaidPending,
    );
    if (mounted) setState(() => _busy = false);
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.turn,
    required this.turnMonth,
    required this.isMe,
    required this.isRecipient,
    required this.payment,
  });

  final String name;
  final int turn;
  final DateTime turnMonth;
  final bool isMe;
  final bool isRecipient;
  final ArisanPayment? payment;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final p = payment;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isRecipient ? AppColors.secondaryContainer : AppColors.surface,
        borderRadius: AppRadius.smBr,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          MemberAvatar(name: name, size: 38),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$name ${l10n.arisanYouTag}' : name,
                  style: text.titleSmall,
                ),
                Text(
                  '${l10n.arisanTurnFormat(turn, shortMonthYear(turnMonth, l10n: l10n))}'
                  '${isRecipient ? ' · ${l10n.arisanReceivingThisMonth}' : ''}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          StatusPill(
            label: p == null
                ? l10n.arisanNotPaidYet
                : p.status == PaymentStatus.confirmed
                ? l10n.arisanPaidStatus
                : l10n.arisanWaitingStatus,
            tone: p == null ? PillTone.neutral : paymentTone(p.status),
          ),
        ],
      ),
    );
  }
}
