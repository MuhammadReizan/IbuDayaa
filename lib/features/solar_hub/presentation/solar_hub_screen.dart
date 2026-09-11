import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/brand/brand.dart';
import '../../../core/data/app_data_controller.dart';
import '../../../core/data/derived_providers.dart';
import '../../../core/data/insights.dart';
import '../../../core/data/models.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/energy.dart';
import '../../../core/format/money.dart';

/// The user's own record of energy taken from the shared hub instead of the
/// grid. Every saving and CO₂ figure in the app traces back to this log.
class SolarHubScreen extends ConsumerWidget {
  const SolarHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final impact = ref.watch(impactProvider);
    final tariff = ref.watch(profileProvider)?.tariffIdrPerKwh ?? 0;
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      titleWidget: const IbuDayaLogo(height: 24),
      actions: [
        IconButton(
          tooltip: 'Cek kelayakan atap',
          icon: const Icon(Icons.roofing_outlined),
          onPressed: () => context.push(AppRoute.roofCheckPath),
        ),
      ],
      bottomBar: PrimaryButton(
        icon: Icons.add_rounded,
        label: 'Catat Pemakaian Hub',
        onPressed: () => context.push(AppRoute.sessionAddPath),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: AppSpacing.hero,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: AppRadius.lgBr,
              boxShadow: AppShadows.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENERGI DARI SOLAR HUB',
                        style: text.labelSmall?.copyWith(
                          color: AppColors.textOnDarkDim,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        formatKwh(impact.solarKwh),
                        style: AppTypography.numeric(30, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sessions.isEmpty
                            ? 'Belum ada pemakaian tercatat'
                            : 'Dari ${sessions.length} kali pemakaian',
                        style: text.bodySmall?.copyWith(
                          color: AppColors.textOnDarkDim,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 84,
                  child: BrandArt(
                    motif: BrandArtMotif.solar,
                    size: 84,
                    onDark: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (impact.solarKwh > 0)
            Row(
              children: [
                Expanded(
                  child: SectionCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: StatTile(
                      label: 'NILAI ENERGI',
                      value: formatRupiah((impact.solarKwh * tariff).round()),
                      valueSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SectionCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: StatTile(
                      label: 'CO₂ DIHINDARI',
                      value: '${impact.co2AvoidedKg.toStringAsFixed(0)} kg',
                      valueSize: 18,
                      qualifier: QualifierKind.estimasi,
                    ),
                  ),
                ),
              ],
            ),
          if (impact.solarKwh > 0) const SizedBox(height: AppSpacing.xl),

          Text('Riwayat Pemakaian', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),

          if (sessions.isEmpty)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Setiap kali Anda memakai alat di Solar Hub, catat di sini. '
                    'Dari catatan ini IbuDaya menghitung penghematan dan emisi '
                    'yang Anda hindari.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    icon: Icons.roofing_outlined,
                    label: 'Cek Kelayakan Atap Dulu',
                    onPressed: () => context.push(AppRoute.roofCheckPath),
                  ),
                ],
              ),
            )
          else
            for (int i = 0; i < sessions.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _SessionRow(session: sessions[i], tariff: tariff),
            ],

          const SizedBox(height: AppSpacing.lg),
          const InfoBanner(
            tone: InfoTone.info,
            message:
                'Nilai penghematan dihitung dari tarif listrik Anda. Emisi '
                'yang dihindari memakai faktor jaringan '
                '$kGridEmissionFactorKgPerKwh kg CO₂ per kWh — sebuah asumsi, '
                'bukan pengukuran.',
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends ConsumerWidget {
  const _SessionRow({required this.session, required this.tariff});

  final SolarSession session;
  final double tariff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          FeatureBadge(
            icon: Icons.wb_sunny_outlined,
            tone: BadgeTone.solar,
            size: 42,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.applianceName,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatShortDayDate(session.date)} · ${session.slotLabel}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatKwh(session.kwh),
                style: AppTypography.numeric(15, color: AppColors.primaryDark),
              ),
              Text(
                '≈ ${formatRupiah((session.kwh * tariff).round())}',
                style: text.labelSmall,
              ),
            ],
          ),
          IconButton(
            tooltip: 'Hapus',
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textTertiary,
            ),
            onPressed: () =>
                ref.read(appDataProvider.notifier).deleteSession(session.id),
          ),
        ],
      ),
    );
  }
}
