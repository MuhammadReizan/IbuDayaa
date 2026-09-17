import 'dart:io' as io;

import 'package:flutter/foundation.dart';
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
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.scaffoldEnergy,
      onBack: () => context.pop(),
      scrollable: records.isNotEmpty,
      bottomBar: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: l10n.energyAddManual,
              icon: Icons.edit_rounded,
              onPressed: () => context.push(Paths.energyAdd),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PrimaryButton(
              label: l10n.actionScan,
              icon: Icons.document_scanner_rounded,
              onPressed: () => context.push(Paths.scan),
            ),
          ),
        ],
      ),
      body: records.isEmpty
          ? EmptyState(
              motif: BrandArtMotif.scan,
              title: l10n.energyEmpty,
              message: l10n.energyEmptyMessage,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  title: l10n.homeCatatanListrik,
                  trailing: TextButton(
                    onPressed: () => context.push(Paths.energyAnalysis),
                    child: Text(l10n.homeAnalysis),
                  ),
                  child: UsageBars(months: months),
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final r in records) ...[
                  _RecordTile(record: r),
                  const SizedBox(height: AppSpacing.sm),
                ],
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
    final l10n = AppLocalizations.of(context);
    final r = record;
    final photo = r.photoPath;

    Future<void> delete() async {
      final ok = await confirmDialog(
        context,
        title: l10n.energyDeleteConfirmTitle,
        message: l10n.energyDeleteConfirmBody,
        confirmLabel: l10n.actionDelete,
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await runAction(
        context,
        () => ref.read(actionsProvider).deleteRecord(r.id),
        success: l10n.energyDeletedToast,
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
              if (photo != null && (kIsWeb || io.File(photo).existsSync()))
                ClipRRect(
                  borderRadius: AppRadius.xsBr,
                  child: kIsWeb
                      ? Image.network(
                          photo,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const SizedBox(width: 44, height: 44),
                        )
                      : Image.file(
                          io.File(photo),
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
                      '${r.kind.localizedLabel(l10n)} · ${monthYearLabel(r.periodMonth)}',
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
