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
import '../shared/labels.dart';

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
    final running = data.loans
        .where((l) => l.status == LoanStatus.disbursed)
        .toList();
    final outstanding = running.fold<int>(
      0,
      (sum, l) =>
          sum +
          data
              .installmentsOf(l.id)
              .where((i) => !i.isPaid)
              .fold<int>(0, (a, i) => a + i.amountIdr),
    );
    final overdue = running
        .expand((l) => data.installmentsOf(l.id))
        .where((i) => i.isOverdue(now))
        .length;
    final hub = data.hub;
    final today = dayCapacity(data.availabilityOn(dayOf(now)));
    final unreadNotif = data.unreadNotificationsOf(me.id);
    final unreadMsg = data.unreadMessagesOf(me);

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
              const SizedBox(height: AppSpacing.lg),
              if (coop != null)
                InviteCodeCard(coop: coop, memberCount: members.length),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, c) {
                  final w = (c.maxWidth - AppSpacing.md) / 2;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      _Stat(
                        width: w,
                        icon: Icons.groups_rounded,
                        label: l10n.navMembers,
                        value: '${members.length}',
                        onTap: () => context.go(Paths.adminMembers),
                      ),
                      _Stat(
                        width: w,
                        icon: Icons.request_page_rounded,
                        label: l10n.labelPending,
                        value: '${waitingLoans.length}',
                        alert: waitingLoans.isNotEmpty,
                        onTap: () => context.go(Paths.adminLoans),
                      ),
                      _Stat(
                        width: w,
                        icon: Icons.payments_rounded,
                        label: l10n.labelPending,
                        value: '${pendingPayments.length}',
                        alert: pendingPayments.isNotEmpty,
                        onTap: () => context.push(Paths.adminPayments),
                      ),
                      _Stat(
                        width: w,
                        icon: Icons.account_balance_rounded,
                        label: l10n.loanInstallments,
                        value: formatRupiah(outstanding),
                        small: true,
                        onTap: () => context.go(Paths.adminLoans),
                      ),
                    ],
                  );
                },
              ),
              if (overdue > 0) ...[
                const SizedBox(height: AppSpacing.md),
                InfoBanner(
                  tone: InfoTone.danger,
                  message: '$overdue ${l10n.homeLoanOverdue}.',
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (hub == null || !hub.isConfigured || data.groups.isEmpty) ...[
                SectionHeader(title: l10n.adminDashTitle),
                if (hub == null || !hub.isConfigured) ...[
                  TintedRow(
                    filled: true,
                    tone: PillTone.warning,
                    icon: Icons.solar_power_rounded,
                    title: l10n.adminHubTitle,
                    subtitle: l10n.solarNoHubMessage,
                    onTap: () => context.push(Paths.adminHub),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (data.groups.isEmpty) ...[
                  TintedRow(
                    filled: true,
                    tone: PillTone.info,
                    icon: Icons.groups_rounded,
                    title: l10n.adminArisanNewGroup,
                    subtitle: members.length < 2
                        ? l10n.arisanNotJoinedMsg
                        : l10n.arisanGroupName,
                    onTap: () => context.push(Paths.adminArisanNew),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
              if (hub != null && hub.isConfigured) ...[
                SectionCard(
                  onTap: () => context.push(Paths.adminHub),
                  child: Row(
                    children: [
                      const FeatureBadge(
                        icon: Icons.solar_power_rounded,
                        tone: BadgeTone.solar,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.solarCapacityToday,
                              style: text.bodySmall,
                            ),
                            Text(
                              '${formatKwh(today.bookedKwh)} / ${formatKwh(today.capacityKwh)}',
                              style: text.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppProgressBar(
                              value: today.capacityKwh <= 0
                                  ? 0
                                  : today.bookedKwh / today.capacityKwh,
                              color: AppColors.secondaryDark,
                              track: AppColors.secondaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              SectionHeader(
                title: l10n.labelPending,
                actionLabel: waitingLoans.isEmpty ? null : l10n.actionViewAll,
                onAction: () => context.go(Paths.adminLoans),
              ),
              if (waitingLoans.isEmpty)
                Text(l10n.adminLoansEmptyMessage, style: text.bodyMedium)
              else
                for (final l in waitingLoans.take(3)) ...[
                  AdminLoanRow(loan: l, name: data.nameOf(l.userId)),
                  const SizedBox(height: AppSpacing.sm),
                ],
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: l10n.adminPaymentsTitle,
                actionLabel: pendingPayments.isEmpty
                    ? null
                    : l10n.actionViewAll,
                onAction: () => context.push(Paths.adminPayments),
              ),
              if (pendingPayments.isEmpty)
                Text(l10n.adminPaymentsEmpty, style: text.bodyMedium)
              else
                for (final p in pendingPayments.take(3)) ...[
                  TintedRow(
                    icon: Icons.payments_rounded,
                    tone: PillTone.warning,
                    title:
                        '${data.nameOf(p.userId)} · ${formatRupiah(p.amountIdr)}',
                    subtitle:
                        '${data.group(p.groupId)?.name ?? ''} · ${monthYearLabel(p.periodMonth, l10n: l10n)}',
                    onTap: () => context.push(Paths.adminPayments),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({
    super.key,
    required this.coop,
    required this.memberCount,
  });

  final Cooperative coop;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memberCount == 0 ? 'Undang anggota pertama Anda' : 'Kode koperasi',
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
                tooltip: 'Salin kode',
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          'Gabung ke ${coop.name} di aplikasi IbuDaya. Pilih Daftar → '
                          'Anggota koperasi, lalu masukkan kode ${coop.inviteCode}.',
                    ),
                  );
                  if (context.mounted) {
                    showAppSnack(context, 'Pesan undangan disalin.');
                  }
                },
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Anggota memasukkan kode ini saat mendaftar. Jangan sebar ke orang di '
            'luar koperasi.',
            style: text.bodySmall?.copyWith(color: AppColors.textOnDarkDim),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.alert = false,
    this.small = false,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool alert;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: SectionCard(
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
          ],
        ),
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
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push(Paths.adminLoan(loan.id)),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.infoContainer,
              borderRadius: AppRadius.xsBr,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${loan.scoreSnapshot}',
                  style: AppTypography.numeric(16, color: AppColors.infoText),
                ),
                Text(
                  'skor',
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
                  '${formatRupiah(loan.amountIdr)} · ${loan.tenorMonths} bln · ${loan.purpose.label}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          StatusPill(label: loan.status.label, tone: loanTone(loan.status)),
        ],
      ),
    );
  }
}
