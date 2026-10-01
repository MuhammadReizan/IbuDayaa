import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/row.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/hub_capacity.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../credit_score/application/credit_score_provider.dart';
import '../shared/labels.dart';

/// The admin's start page: the numbers an admin acts on as icon tiles (red when
/// something is waiting), then the cooperative summary. Tiles that would only
/// repeat a bottom tab as a menu are left out.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final coop = data.cooperative;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final members = data.memberProfiles;
    final waitingLoans = data.loansAwaitingAdmin;
    final pendingPayments = data.pendingPayments;
    final awaitingInstallments = data.installmentsAwaiting;
    final hubRequests = data.hubRequests;
    final kpis = data.coopKpisOf(now, ref.read(creditScoringEngineProvider));
    final open = data.openInstallments;
    final outstanding = open.fold<int>(0, (a, i) => a + i.amountIdr);
    final overdue = open
        .where((i) => !i.isAwaitingConfirmation && i.isOverdue(now))
        .length;
    final hub = data.hub;
    final hubReady = hub != null && hub.isConfigured;
    final today = dayCapacity(data.availabilityOn(dayOf(now)));
    final usedPct = today.capacityKwh <= 0
        ? 0
        : (today.bookedKwh / today.capacityKwh * 100).round();
    final unreadNotif = data.unreadNotificationsOf(me.id);
    final unreadMsg = data.unreadMessagesOf(me);

    Widget setup({
      required PillTone tone,
      required IconData icon,
      required String title,
      required String subtitle,
      required String path,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TintedRow(
        filled: true,
        tone: tone,
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: () => context.push(path),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: ref.read(appStateProvider.notifier).refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.scaffoldAdminDashboard,
                          style: text.bodySmall,
                        ),
                        Text(
                          coop?.name ?? '-',
                          style: text.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.navMessages,
                    onPressed: () => context.push(Paths.adminMessages),
                    icon: Badge(
                      isLabelVisible: unreadMsg > 0,
                      label: Text('$unreadMsg'),
                      backgroundColor: AppColors.danger,
                      child: const Icon(Icons.chat_bubble_outline_rounded),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.scaffoldNotifications,
                    onPressed: () => context.push(Paths.notifications),
                    icon: Badge(
                      isLabelVisible: unreadNotif > 0,
                      label: Text('$unreadNotif'),
                      backgroundColor: AppColors.danger,
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (coop != null)
                InviteCodeCard(
                  coop: coop,
                  memberCount: members.length,
                  compact: members.isNotEmpty,
                ),
              const SizedBox(height: AppSpacing.lg),
              if (!hubReady)
                setup(
                  tone: PillTone.warning,
                  icon: Icons.solar_power_rounded,
                  title: l10n.adminHubTitle,
                  subtitle: l10n.solarNoHubMessage,
                  path: Paths.adminHub,
                ),
              if (data.groups.isEmpty)
                setup(
                  tone: PillTone.info,
                  icon: Icons.groups_rounded,
                  title: l10n.adminArisanNewGroup,
                  subtitle: members.length < 2
                      ? l10n.arisanNotJoinedMsg
                      : l10n.arisanGroupName,
                  path: Paths.adminArisanNew,
                ),
              // Numbers an admin acts on, each a tap into the place to act.
              // Red = something is waiting. The tabs already cover the member
              // list and the application list, so these are counts and
              // amounts, not menus.
              _StatGrid(
                children: [
                  _Stat(
                    icon: Icons.request_page_rounded,
                    label: l10n.adminTodoLoans,
                    value: '${waitingLoans.length}',
                    alert: waitingLoans.isNotEmpty,
                    onTap: () => context.go(Paths.adminLoans),
                  ),
                  _Stat(
                    icon: Icons.payments_rounded,
                    label: l10n.adminPaymentsMenu,
                    value: '${pendingPayments.length}',
                    alert: pendingPayments.isNotEmpty,
                    onTap: () => context.push(Paths.adminPayments),
                  ),
                  _Stat(
                    icon: Icons.fact_check_rounded,
                    label: l10n.adminTodoInstallments,
                    value: '${awaitingInstallments.length}',
                    alert: awaitingInstallments.isNotEmpty,
                    onTap: () => context.push(Paths.adminInstallments),
                  ),
                  _Stat(
                    icon: Icons.qr_code_scanner_rounded,
                    label: l10n.adminRequestsCardTitle,
                    value: '${hubRequests.length}',
                    alert: hubRequests.isNotEmpty,
                    onTap: () => context.push(Paths.adminHubRequests),
                  ),
                  _Stat(
                    icon: Icons.account_balance_rounded,
                    label: l10n.loanInstallments,
                    value: formatRupiah(outstanding),
                    caption: overdue > 0
                        ? '${l10n.adminInstOverdueLabel}: $overdue'
                        : l10n.adminInstOutstanding,
                    small: true,
                    alert: overdue > 0,
                    onTap: () => context.push(Paths.adminInstallments),
                  ),
                  _Stat(
                    icon: Icons.solar_power_rounded,
                    label: l10n.solarCapacityToday,
                    value: hubReady ? '$usedPct%' : '-',
                    caption: hubReady
                        ? '${formatKwh(today.bookedKwh)} / ${formatKwh(today.capacityKwh)}'
                        : null,
                    onTap: () => context.push(
                      hubReady ? Paths.adminHubBoard : Paths.adminHub,
                    ),
                  ),
                  _Stat(
                    icon: Icons.groups_rounded,
                    label: l10n.adminSummaryActive,
                    value: '${kpis.activeMembers}/${kpis.members}',
                    onTap: () => context.go(Paths.adminMembers),
                  ),
                  _Stat(
                    icon: Icons.verified_rounded,
                    label: l10n.adminSummaryLoanReady,
                    value: '${kpis.loanReady}',
                    onTap: () => context.push(Paths.adminSummary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TintedRow(
                icon: Icons.insights_rounded,
                tone: PillTone.info,
                title: l10n.adminKpiTitle,
                subtitle: l10n.adminSummarySubtitle(
                  kpis.activeMembers,
                  kpis.members,
                  kpis.loanReady,
                  kpis.quotaTrades,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
                onTap: () => context.push(Paths.adminSummary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two tiles to a row, each row as tall as its tallest tile.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (int i = 0; i < children.length; i += 2)
        Padding(
          padding: EdgeInsets.only(
            bottom: i + 2 < children.length ? AppSpacing.md : 0,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: i + 1 < children.length
                      ? children[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.caption,
    this.alert = false,
    this.small = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  /// A second, quieter line under the label (an amount, a ratio).
  final String? caption;
  final bool alert;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeatureBadge(
            icon: icon,
            size: 36,
            tone: alert ? BadgeTone.alert : BadgeTone.mint,
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTypography.numeric(small ? 18 : 26)),
          ),
          Text(label, style: text.bodySmall, maxLines: 2),
          if (caption != null)
            Text(
              caption!,
              style: text.labelSmall?.copyWith(
                color: alert ? AppColors.dangerText : AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({
    super.key,
    required this.coop,
    required this.memberCount,
    this.compact = false,
  });

  final Cooperative coop;
  final int memberCount;

  /// One slim row once members have joined: the code is still there to copy,
  /// but it no longer takes the top of the dashboard.
  final bool compact;

  Future<void> _copy(BuildContext context, AppLocalizations l10n) async {
    await Clipboard.setData(
      ClipboardData(
        text: l10n.inviteCardShareMessage(coop.name, coop.inviteCode),
      ),
    );
    if (context.mounted) showAppSnack(context, l10n.inviteCardCopiedToast);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    if (compact) {
      return SectionCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const FeatureBadge(icon: Icons.vpn_key_rounded, size: 36),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.inviteCardTitle, style: text.bodySmall),
                  Text(
                    coop.inviteCode,
                    style: AppTypography.numeric(20).copyWith(letterSpacing: 3),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.inviteCardCopyTooltip,
              onPressed: () => _copy(context, l10n),
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
      );
    }

    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memberCount == 0
                ? l10n.inviteCardFirstMember
                : l10n.inviteCardTitle,
            style: text.labelLarge?.copyWith(color: AppColors.textOnDarkDim),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    coop.inviteCode,
                    style: AppTypography.numeric(
                      36,
                      color: Colors.white,
                    ).copyWith(letterSpacing: 6),
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: l10n.inviteCardCopyTooltip,
                onPressed: () => _copy(context, l10n),
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.inviteCardCaption,
            style: text.bodySmall?.copyWith(color: AppColors.textOnDarkDim),
          ),
        ],
      ),
    );
  }
}

class AdminLoanRow extends StatelessWidget {
  const AdminLoanRow({super.key, required this.loan, required this.name});

  final LoanApplication loan;
  final String name;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push(Paths.adminLoan(loan.id)),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 46, minHeight: 46),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.infoContainer,
              borderRadius: AppRadius.xsBr,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${loan.scoreSnapshot}',
                  style: AppTypography.numeric(16, color: AppColors.infoText),
                ),
                Text(
                  l10n.scoreShortLabel.toLowerCase(),
                  style: text.labelSmall?.copyWith(
                    fontSize: 9,
                    color: AppColors.infoText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.titleSmall),
                Text(
                  '${formatRupiah(loan.amountIdr)} · '
                  '${l10n.unitMonths(loan.tenorMonths)} · '
                  '${loan.purpose.localizedLabel(l10n)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          StatusPill(
            label: loan.status.localizedLabel(l10n),
            tone: loanTone(loan.status),
          ),
        ],
      ),
    );
  }
}
