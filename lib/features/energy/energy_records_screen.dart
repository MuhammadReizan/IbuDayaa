import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/logic/credit_signals.dart';
import '../../core/logic/energy_insights.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import 'usage_bars.dart';

class EnergyRecordsScreen extends ConsumerWidget {
  const EnergyRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final records = s.data.recordsOf(me.id);
    final months = monthlyUsage(records);
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Catatan Listrik',
      onBack: () => context.pop(),
      scrollable: records.isNotEmpty,
      bottomBar: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Isi manual',
              icon: Icons.edit_rounded,
              onPressed: () => context.push(Paths.energyAdd),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PrimaryButton(
              label: 'Scan',
              icon: Icons.document_scanner_rounded,
              onPressed: () => context.push(Paths.scan),
            ),
          ),
        ],
      ),
      body: records.isEmpty
          ? const EmptyState(
              motif: BrandArtMotif.scan,
              title: 'Belum ada catatan listrik',
              message:
                  'Scan tagihan atau struk token PLN. Catat minimal '
                  '$kMinMonthsForScore bulan agar analisis dan Skor Kredit '
                  'Energi bisa dihitung.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  title: 'Pemakaian per bulan',
                  trailing: TextButton(
                    onPressed: () => context.push(Paths.energyAnalysis),
                    child: const Text('Analisis'),
                  ),
                  child: UsageBars(months: months),
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final r in records) ...[
                  _RecordTile(record: r),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tahan lama sebuah catatan untuk menghapusnya.',
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}

class _RecordTile extends ConsumerWidget {
  const _RecordTile({required this.record});

  final EnergyRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final r = record;
    final photo = r.photoPath;

    Future<void> delete() async {
      final ok = await confirmDialog(
        context,
        title: 'Hapus catatan?',
        message:
            '${r.kind.label} ${monthYearLabel(r.periodMonth)} '
            '(${formatKwh(r.kwh)}, ${formatRupiah(r.totalIdr)}) akan dihapus.',
        confirmLabel: 'Hapus',
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await runAction(
        context,
        () => ref.read(actionsProvider).deleteRecord(r.id),
        success: 'Catatan dihapus.',
      );
    }

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.smBr,
      child: InkWell(
        borderRadius: AppRadius.smBr,
        onLongPress: delete,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smBr,
            border: Border.all(color: AppColors.outlineSubtle),
          ),
          child: Row(
            children: [
              if (photo != null && File(photo).existsSync())
                ClipRRect(
                  borderRadius: AppRadius.xsBr,
                  child: Image.file(
                    File(photo),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              else
                FeatureBadge(
                  icon: r.kind == EnergyKind.token
                      ? Icons.bolt_rounded
                      : Icons.receipt_long_rounded,
                  tone: r.kind == EnergyKind.token
                      ? BadgeTone.solar
                      : BadgeTone.mint,
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r.kind.label} · ${monthYearLabel(r.periodMonth)}',
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatKwh(r.kwh)} · ${formatRupiah(r.idrPerKwh)}/kWh',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatRupiah(r.totalIdr), style: text.titleSmall),
                  const SizedBox(height: 2),
                  StatusPill(
                    label: r.source == RecordSource.scan ? 'Scan' : 'Manual',
                    tone: r.source == RecordSource.scan
                        ? PillTone.success
                        : PillTone.neutral,
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Hapus',
                onPressed: delete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
