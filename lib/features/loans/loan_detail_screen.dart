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
import '../credit_score/application/credit_score_provider.dart';
import '../shared/labels.dart';

/// One application, for the member who made it or an admin reviewing it.
class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({
    super.key,
    required this.loanId,
    this.adminView = false,
  });

  final String loanId;
  final bool adminView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final loan = data.loan(loanId);
    final text = Theme.of(context).textTheme;
    final now = ref.read(clockProvider)();

    if (loan == null) {
      return AppScaffold(
        title: 'Pengajuan',
        onBack: () => context.pop(),
        scrollable: false,
        body: const EmptyState(title: 'Pengajuan tidak ditemukan'),
      );
    }

    final isAdmin = adminView && me.isAdmin;
    final member = data.profile(loan.userId);
    final events = data.eventsOf(loan.id);
    final installments = data.installmentsOf(loan.id);
    final paid = installments
        .where((i) => i.isPaid)
        .fold<int>(0, (a, i) => a + i.amountIdr);
    final actions = ref.read(actionsProvider);

    final upcoming = switch (loan.status) {
      LoanStatus.submitted => [
        'Review admin',
        'Keputusan admin',
        'Dana dicairkan',
      ],
      LoanStatus.inReview => ['Keputusan admin', 'Dana dicairkan'],
      LoanStatus.approved => ['Dana dicairkan'],
      LoanStatus.disbursed => ['Semua cicilan lunas'],
      _ => const <String>[],
    };

    Future<void> act(Future<void> Function() run, String success) =>
        runAction(context, run, success: success);

    final bottom = <Widget>[
      if (isAdmin && loan.status == LoanStatus.submitted) ...[
        _reject(context, actions, loan),
        PrimaryButton(
          label: 'Mulai review',
          onPressed: () => act(
            () => actions.startLoanReview(loan.id),
            'Status: sedang direview.',
          ),
        ),
      ],
      if (isAdmin && loan.status == LoanStatus.inReview) ...[
        _reject(context, actions, loan),
        PrimaryButton(
          label: 'Setujui',
          onPressed: () async {
            final note = await promptText(
              context,
              title: 'Setujui pengajuan?',
              label: 'Catatan untuk anggota (boleh kosong)',
              confirmLabel: 'Setujui',
              required: false,
            );
            if (note == null || !context.mounted) return;
            await act(
              () => actions.approveLoan(loan.id, note: note),
              'Pengajuan disetujui.',
            );
          },
        ),
      ],
      if (isAdmin && loan.status == LoanStatus.approved)
        PrimaryButton(
          label: 'Catat dana dicairkan',
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              title: 'Dana sudah diserahkan?',
              message:
                  'Catat pencairan hanya setelah ${formatRupiah(loan.amountIdr)} '
                  'benar-benar diterima ${member?.fullName ?? 'anggota'}. Jadwal '
                  'cicilan akan dibuat mulai hari ini.',
              confirmLabel: 'Ya, sudah dicairkan',
            );
            if (!ok || !context.mounted) return;
            await act(
              () => actions.disburseLoan(loan.id),
              'Pencairan dicatat.',
            );
          },
        ),
      if (!isAdmin &&
          loan.userId == me.id &&
          loan.status == LoanStatus.submitted)
        SecondaryButton(
          label: 'Batalkan pengajuan',
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              title: 'Batalkan pengajuan?',
              message:
                  'Pengajuan ini akan ditutup. Anda bisa mengajukan lagi nanti.',
              confirmLabel: 'Batalkan',
              destructive: true,
            );
            if (!ok || !context.mounted) return;
            await act(
              () => actions.cancelLoan(loan.id),
              'Pengajuan dibatalkan.',
            );
          },
        ),
    ];

    final currentScore = isAdmin
        ? data.scoreOf(loan.userId, now, ref.read(creditScoringEngineProvider))
        : null;
    final support = data.supportThreadOf(loan.userId);

    return AppScaffold(
      title: isAdmin ? 'Review Pengajuan' : 'Status Pengajuan',
      onBack: () => context.pop(),
      bottomBar: bottom.isEmpty
          ? null
          : Row(
              children: [
                for (int i = 0; i < bottom.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(child: bottom[i]),
                ],
              ],
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatRupiah(loan.amountIdr),
                        style: AppTypography.numeric(28),
                      ),
                    ),
                    StatusPill(
                      label: loan.status.label,
                      tone: loanTone(loan.status),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${loan.purpose.label} · diajukan ${formatLongDate(loan.createdAt)}',
                  style: text.bodySmall,
                ),
                const Divider(height: AppSpacing.xl),
                KeyValueRow(label: 'Tenor', value: '${loan.tenorMonths} bulan'),
                KeyValueRow(
                  label: 'Jasa per bulan (flat)',
                  value: formatPercent(loan.flatMonthlyRatePct, decimals: 1),
                ),
                KeyValueRow(
                  label: 'Cicilan per bulan',
                  value: formatRupiah(loan.monthlyInstallmentIdr),
                  emphasize: true,
                ),
                KeyValueRow(
                  label: 'Total dikembalikan',
                  value: formatRupiah(loan.totalRepaymentIdr),
                ),
                if (loan.note != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Keterangan: "${loan.note}"', style: text.bodyMedium),
                ],
              ],
            ),
          ),
          if (loan.decisionNote != null) ...[
            const SizedBox(height: AppSpacing.md),
            InfoBanner(
              tone: loan.status == LoanStatus.rejected
                  ? InfoTone.danger
                  : InfoTone.success,
              title: loan.status == LoanStatus.rejected
                  ? 'Alasan dari admin'
                  : 'Catatan admin',
              message: loan.decisionNote!,
            ),
          ],
          if (isAdmin && member != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              child: Row(
                children: [
                  MemberAvatar(name: member.fullName, size: 44),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.fullName, style: text.titleSmall),
                        Text(
                          '${member.businessName} · ${member.displayPhone}',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kirim pesan',
                    onPressed: support == null
                        ? null
                        : () => context.push(Paths.thread(support.id)),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  IconButton(
                    tooltip: 'Profil anggota',
                    onPressed: () => context.push(Paths.adminMember(member.id)),
                    icon: const Icon(Icons.person_search_outlined),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title:
                'Skor saat mengajukan: ${loan.scoreSnapshot} (${loan.scoreBand})',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in loan.scoreFactors) ...[
                  Row(
                    children: [
                      Expanded(child: Text(f.label, style: text.bodyMedium)),
                      Text(
                        '${f.points}/${f.maxPoints}',
                        style: text.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppProgressBar(
                    value: f.maxPoints == 0 ? 0 : f.points / f.maxPoints,
                    height: 6,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (currentScore != null &&
                    currentScore.score != loan.scoreSnapshot)
                  Text(
                    'Skor anggota sekarang: ${currentScore.score} (${currentScore.band.label}).',
                    style: text.bodySmall,
                  ),
              ],
            ),
          ),
          if (installments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: 'Cicilan',
              trailing: Text(
                '${formatRupiah(paid)} / ${formatRupiah(loan.totalRepaymentIdr)}',
                style: text.labelMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppProgressBar(
                    value: loan.totalRepaymentIdr == 0
                        ? 0
                        : paid / loan.totalRepaymentIdr,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final i in installments)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text('${i.seq}', style: text.titleSmall),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatRupiah(i.amountIdr),
                                  style: text.titleSmall,
                                ),
                                Text(
                                  i.isPaid
                                      ? 'Dibayar ${formatShortDate(i.paidAt!)}'
                                      : 'Jatuh tempo ${formatShortDate(i.dueDate)} ${i.dueDate.year}',
                                  style: text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (i.isPaid)
                            StatusPill(
                              label: i.paidOnTime ? 'Lunas' : 'Lunas terlambat',
                              tone: i.paidOnTime
                                  ? PillTone.success
                                  : PillTone.warning,
                            )
                          else if (isAdmin &&
                              loan.status == LoanStatus.disbursed)
                            TextButton(
                              onPressed: () async {
                                final ok = await confirmDialog(
                                  context,
                                  title: 'Cicilan ke-${i.seq} diterima?',
                                  message:
                                      'Catat hanya jika ${formatRupiah(i.amountIdr)} sudah '
                                      'diterima koperasi.',
                                  confirmLabel: 'Catat diterima',
                                );
                                if (!ok || !context.mounted) return;
                                await act(
                                  () => actions.markInstallmentPaid(i.id),
                                  'Cicilan dicatat.',
                                );
                              },
                              child: const Text('Terima'),
                            )
                          else
                            StatusPill(
                              label: i.isOverdue(now) ? 'Terlambat' : 'Belum',
                              tone: i.isOverdue(now)
                                  ? PillTone.danger
                                  : PillTone.neutral,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Riwayat',
            child: Column(
              children: [
                for (int i = 0; i < events.length; i++)
                  TimelineItem(
                    title: loanEventLabel(events[i].type),
                    subtitle: [
                      if (events[i].actorId != null)
                        data.nameOf(events[i].actorId),
                      if (events[i].note != null) events[i].note!,
                    ].join(' · '),
                    time: formatDateTime(events[i].createdAt),
                    tone:
                        events[i].type == 'rejected' ||
                            events[i].type == 'cancelled'
                        ? PillTone.danger
                        : PillTone.success,
                    isLast: i == events.length - 1 && upcoming.isEmpty,
                  ),
                for (int i = 0; i < upcoming.length; i++)
                  TimelineItem(
                    title: upcoming[i],
                    done: false,
                    isLast: i == upcoming.length - 1,
                  ),
              ],
            ),
          ),
          if (!isAdmin) ...[
            const SizedBox(height: AppSpacing.lg),
            const LoanDecisionNotice(),
          ],
        ],
      ),
    );
  }

  Widget _reject(
    BuildContext context,
    AppActions actions,
    LoanApplication loan,
  ) => SecondaryButton(
    label: 'Tolak',
    onPressed: () async {
      final reason = await promptText(
        context,
        title: 'Tolak pengajuan?',
        label: 'Alasan (akan dibaca anggota)',
        confirmLabel: 'Tolak',
        destructive: true,
      );
      if (reason == null || !context.mounted) return;
      await runAction(
        context,
        () => actions.rejectLoan(loan.id, reason),
        success: 'Pengajuan ditolak.',
      );
    },
  );
}
