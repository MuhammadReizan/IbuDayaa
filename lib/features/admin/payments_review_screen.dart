import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
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
      title: 'Konfirmasi Setoran',
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
          SectionHeader(title: 'Menunggu (${pending.length})'),
          if (pending.isEmpty)
            SectionCard(
              child: Row(
                children: [
                  const BrandArt(motif: BrandArtMotif.success, size: 56),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Semua setoran sudah diproses.',
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
                                '${data.group(p.groupId)?.name ?? ''} · ${monthYearLabel(p.periodMonth)}',
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
                      'Dikirim ${formatDateTime(p.createdAt)}',
                      style: text.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Tolak',
                            onPressed: () async {
                              final reason = await promptText(
                                context,
                                title: 'Tolak setoran?',
                                label: 'Alasan (dibaca anggota)',
                                confirmLabel: 'Tolak',
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
                                success: 'Setoran ditolak.',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Konfirmasi',
                            onPressed: () => runAction(
                              context,
                              () => actions.reviewPayment(p.id, approve: true),
                              success:
                                  'Setoran ${data.nameOf(p.userId)} dikonfirmasi.',
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
            const SectionHeader(title: 'Sudah diproses'),
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
                      '${monthYearLabel(p.periodMonth)}${p.note == null ? '' : ' · ${p.note}'}',
                  trailing: StatusPill(
                    label: p.status.label,
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
