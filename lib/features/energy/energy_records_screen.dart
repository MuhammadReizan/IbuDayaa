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
import 'usage_bars.dart';

class EnergyRecordsScreen extends ConsumerWidget {
  const EnergyRecordsScreen({super.key, this.embedded = false});

  /// True when shown as a bottom-nav tab, where there is nothing to pop to.
  final bool embedded;

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
      onBack: embedded ? null : () => context.pop(),
      scrollable: records.isNotEmpty,
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
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.energyAutoNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final r in records) ...[
                  _RecordTile(
                    record: r,
                    booking: s.data.bookings
                        .where((b) => b.id == r.bookingId)
                        .firstOrNull,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, this.booking});

  final EnergyRecord record;

  /// The hub session that produced [record], when it is still known.
  final HubBooking? booking;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final r = record;
    final isHub = r.source == RecordSource.hub;
    final b = booking;
    // A hub session is stored with kind=token internally (it accumulates the
    // same way a token purchase does) but must never be labelled "Token" —
    // the source already says where it came from.
    final title = isHub
        ? (b != null && b.applianceName.isNotEmpty
              ? '${l10n.energySourceHub} · ${b.applianceName}'
              : l10n.energySourceHub)
        : r.kind.localizedLabel(l10n);
    final when = b != null
        ? formatShortDate(b.bookingDate, l10n: l10n)
        : monthYearLabel(r.periodMonth);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.smBr,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          FeatureBadge(
            icon: isHub
                ? Icons.solar_power_rounded
                : r.kind == EnergyKind.token
                ? Icons.bolt_rounded
                : Icons.receipt_long_rounded,
            tone: isHub || r.kind == EnergyKind.token
                ? BadgeTone.solar
                : BadgeTone.mint,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '$when · ${formatKwh(r.kwh)} · ${formatRupiah(r.idrPerKwh)}/kWh',
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
                label: isHub ? l10n.energySourceHub : l10n.energySourceManual,
                tone: isHub ? PillTone.success : PillTone.neutral,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
