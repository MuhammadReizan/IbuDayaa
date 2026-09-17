import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/energy_insights.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../credit_score/application/credit_score_provider.dart';
import '../profile/profile_screen.dart';
import '../shared/labels.dart';
import 'admin_home_screen.dart';

class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStateProvider).data;
    final m = data.profile(memberId);
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    if (m == null) {
      return AppScaffold(
        title: l10n.adminMembersTitle,
        onBack: () => context.pop(),
        scrollable: false,
        body: EmptyState(title: l10n.adminMemberNotFound),
      );
    }

    final score = data.scoreOf(
      m.id,
      now,
      ref.read(creditScoringEngineProvider),
    );
    final readiness = data.readinessOf(m.id, now);
    final months = monthlyUsage(data.recordsOf(m.id));
    final sessions = data
        .bookingsOf(m.id)
        .where((b) => b.status == BookingStatus.completed)
        .length;
    final loans = data.loansOf(m.id);
    final groups = data.groupsOf(m.id);
    final support = data.supportThreadOf(m.id);

    return AppScaffold(
      title: l10n.adminMemberDetailTitle,
      onBack: () => context.pop(),
      bottomBar: support == null
          ? null
          : PrimaryButton(
              label: l10n.adminMemberSendMessage,
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () => context.push(Paths.thread(support.id)),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeader(me: m),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            child: Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: l10n.profileMonthsRecorded,
                    value: '${months.length}',
                  ),
                ),
                Expanded(
                  child: StatTile(
                    label: l10n.profileHubSessions,
                    value: '$sessions',
                  ),
                ),
                Expanded(
                  child: StatTile(
                    label: l10n.scoreShortLabel,
                    value: score == null ? '–' : '${score.score}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: score == null
                ? l10n.adminMemberNoScore
                : l10n.scoreWithBand(score.score, score.band.localizedLabel(l10n)),
            child: score == null
                ? Text(readiness.missing.join('\n'), style: text.bodySmall)
                : Column(
                    children: [
                      for (final f in score.factors) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(f.label, style: text.bodyMedium),
                            ),
                            Text(
                              '${f.points}/${f.maxPoints}',
                              style: text.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppProgressBar(
                          value: f.points / f.maxPoints,
                          height: 6,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
          ),
          if (months.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: l10n.adminMemberElectricityLast3Months,
              child: Column(
                children: [
                  for (final u in months.take(3))
                    KeyValueRow(
                      label: monthYearLabel(u.month),
                      value:
                          '${formatKwh(u.kwh)} · ${formatRupiah(u.totalIdr)}',
                    ),
                ],
              ),
            ),
          ],
          if (groups.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: l10n.adminMemberArisanSection,
              child: Column(
                children: [
                  for (final g in groups)
                    Builder(
                      builder: (_) {
                        final p = data.contributionFor(g.id, m.id, now);
                        return Row(
                          children: [
                            Expanded(
                              child: Text(g.name, style: text.bodyMedium),
                            ),
                            StatusPill(
                              label: p == null
                                  ? l10n.arisanNotPaidYet
                                  : p.status.localizedLabel(l10n),
                              tone: p == null
                                  ? PillTone.neutral
                                  : paymentTone(p.status),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: l10n.adminMemberLoansSection),
          if (loans.isEmpty)
            Text(l10n.adminMemberNoLoans, style: text.bodyMedium)
          else
            for (final l in loans) ...[
              AdminLoanRow(loan: l, name: formatShortDate(l.createdAt)),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}
