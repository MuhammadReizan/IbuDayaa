import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../shared/labels.dart';

class PaymentsReviewScreen extends ConsumerWidget {
  const PaymentsReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStateProvider).data;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final pending = data.pendingPayments;
    final processed =
        data.payments
            .where(
              (p) =>
                  p.type == PaymentType.contribution &&
                  p.status != PaymentStatus.pending,
            )
            .toList()
          ..sort(
            (a, b) => (b.reviewedAt ?? b.createdAt).compareTo(
              a.reviewedAt ?? a.createdAt,
            ),
          );
    final actions = ref.read(actionsProvider);

    return AppScaffold(
      title: l10n.scaffoldAdminPayments,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InfoBanner(
            tone: InfoTone.info,
            message:
                'Konfirmasi hanya setelah uang benar-benar diterima bendahara. '
                'Setoran yang dikonfirmasi ikut menaikkan skor anggota.',
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: '${l10n.labelPending} (${pending.length})'),
          if (pending.isEmpty)
            SectionCard(
              child: Row(
                children: [
                  const BrandArt(motif: BrandArtMotif.success, size: 56),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.adminPaymentsEmpty,
                      style: text.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final p in pending) ...[
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        MemberAvatar(name: data.nameOf(p.userId), size: 40),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.nameOf(p.userId),
                                style: text.titleSmall,
                              ),
                              Text(
                                '${data.group(p.groupId)?.name ?? ''} · ${monthYearLabel(p.periodMonth, l10n: l10n)}',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(p.amountIdr),
                          style: text.titleMedium,
                        ),
                      ],
                    ),
                    if (p.note != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text('"${p.note}"', style: text.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      formatDateTime(p.createdAt, l10n: l10n),
                      style: text.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: l10n.adminPaymentsReject,
                            onPressed: () async {
                              final reason = await promptText(
                                context,
                                title: l10n.adminPaymentsReject,
                                label: l10n.labelNote,
                                confirmLabel: l10n.adminPaymentsReject,
                                destructive: true,
                              );
                              if (reason == null || !context.mounted) return;
                              await runAction(
                                context,
                                () => actions.reviewPayment(
                                  p.id,
                                  approve: false,
                                  note: reason,
                                ),
                                success: l10n.paymentToastRejected,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: PrimaryButton(
                            label: l10n.adminPaymentsApprove,
                            onPressed: () => runAction(
                              context,
                              () => actions.reviewPayment(p.id, approve: true),
                              success: l10n.paymentToastConfirmed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          if (processed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: l10n.labelCompleted),
            for (final p in processed.take(20))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TintedRow(
                  icon: p.status == PaymentStatus.confirmed
                      ? Icons.check_rounded
                      : Icons.close_rounded,
                  tone: paymentTone(p.status),
                  title:
                      '${data.nameOf(p.userId)} · ${formatRupiah(p.amountIdr)}',
                  subtitle:
                      '${monthYearLabel(p.periodMonth, l10n: l10n)}${p.note == null ? '' : ' · ${p.note}'}',
                  trailing: StatusPill(
                    label: p.status.localizedLabel(l10n),
                    tone: paymentTone(p.status),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
