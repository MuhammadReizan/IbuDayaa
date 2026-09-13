import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/paths.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../shared/labels.dart';

class AppliancesScreen extends ConsumerWidget {
  const AppliancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final list = s.data.appliancesOf(me.id);
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final totalKwh = list.fold<double>(0, (a, x) => a + x.monthlyKwh);

    return AppScaffold(
      title: l10n.scaffoldAppliances,
      onBack: () => context.pop(),
      scrollable: list.isNotEmpty,
      bottomBar: PrimaryButton(
        label: l10n.appliancesAdd,
        icon: Icons.add_rounded,
        onPressed: () => context.push(Paths.applianceEdit),
      ),
      body: list.isEmpty
          ? EmptyState(
              motif: BrandArtMotif.solar,
              title: l10n.appliancesEmpty,
              message: l10n.appliancesEmptyMessage,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  tone: CardTone.mint,
                  child: Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Perkiraan per bulan',
                          value: formatKwh(totalKwh),
                        ),
                      ),
                      Expanded(
                        child: StatTile(
                          label: 'Biaya',
                          value: formatRupiah(totalKwh * me.tariffIdrPerKwh),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final a in list) ...[
                  TintedRow(
                    icon: applianceIcon(a.kind),
                    tone: PillTone.success,
                    title: a.name,
                    subtitle:
                        '${a.watts.round()} W · ${formatKwhValue(a.hoursPerDay)} jam/hari · '
                        '${a.daysPerWeek} hari/minggu',
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatKwh(a.monthlyKwh), style: text.titleSmall),
                        Text(
                          formatRupiah(a.monthlyCostIdr(me.tariffIdrPerKwh)),
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                    onTap: () => context.push(Paths.applianceEdit, extra: a),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}
