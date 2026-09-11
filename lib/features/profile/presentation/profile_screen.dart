import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/brand/brand.dart';
import '../../../core/data/app_data_controller.dart';
import '../../../core/data/derived_providers.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/energy.dart';

/// Identity, cumulative impact, and the way into settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final impact = ref.watch(impactProvider);
    final data = ref.watch(dataProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Profil', style: text.headlineSmall),
              const SizedBox(height: AppSpacing.lg),

              Container(
                padding: AppSpacing.card,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: AppRadius.lgBr,
                  boxShadow: AppShadows.md,
                ),
                child: Row(
                  children: [
                    MemberAvatar(name: profile?.name ?? 'Ibu', size: 58),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.name ?? '—',
                            style: text.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (profile?.businessName.isNotEmpty == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: AppRadius.pillBr,
                              ),
                              child: Text(
                                profile!.businessName,
                                style: text.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            [
                              if (profile?.city.isNotEmpty == true)
                                profile!.city,
                              'Sejak ${formatMonthYear(profile?.joinedAt ?? DateTime.now())}',
                            ].join('  ·  '),
                            style: text.bodySmall?.copyWith(
                              color: AppColors.textOnDarkDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ubah profil',
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => context.push(AppRoute.appSettingsPath),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  Expanded(child: Text('Dampak Saya', style: text.titleMedium)),
                  if (impact.hasData)
                    const QualifierLabel(QualifierKind.estimasi),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (!impact.hasData)
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Belum ada yang bisa dihitung. Catat tagihan dan '
                        'pemakaian Solar Hub Anda, lalu angka-angka di sini '
                        'akan terisi sendiri.',
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SecondaryButton(
                        label: 'Catat Tagihan',
                        onPressed: () => context.push(AppRoute.billAddPath),
                      ),
                    ],
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _ImpactCard(
                        icon: Icons.bolt_outlined,
                        tone: BadgeTone.solar,
                        label: 'LISTRIK PLN',
                        value: formatKwh(impact.gridKwh),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ImpactCard(
                        icon: Icons.wb_sunny_outlined,
                        tone: BadgeTone.mint,
                        label: 'DARI SOLAR HUB',
                        value: formatKwh(impact.solarKwh),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _ImpactCard(
                        icon: Icons.eco_outlined,
                        tone: BadgeTone.mint,
                        label: 'CO₂ DIHINDARI',
                        value: '${impact.co2AvoidedKg.toStringAsFixed(0)} kg',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ImpactCard(
                        icon: Icons.groups_2_outlined,
                        tone: BadgeTone.sky,
                        label: 'ANGGOTA GRUP',
                        value: impact.groupSize == 0
                            ? '—'
                            : '${impact.groupSize}',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              Text('Catatan Saya', style: text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(
                      icon: Icons.receipt_long_outlined,
                      label: 'Tagihan Listrik',
                      trailing: '${data.bills.length}',
                      onTap: () => context.push(AppRoute.billsPath),
                    ),
                    const Divider(height: 1),
                    _Row(
                      icon: Icons.electrical_services_outlined,
                      label: 'Alat Usaha',
                      trailing: '${data.appliances.length}',
                      onTap: () => context.push(AppRoute.appliancesPath),
                    ),
                    const Divider(height: 1),
                    _Row(
                      icon: Icons.calculate_outlined,
                      label: 'Perhitungan Cicilan',
                      trailing: '${data.calculations.length}',
                      onTap: () => context.push(AppRoute.financingPath),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Pengaturan', style: text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(
                      icon: Icons.info_outline_rounded,
                      label: 'Tentang IbuDaya',
                      onTap: () => context.push(AppRoute.aboutPath),
                    ),
                    const Divider(height: 1),
                    _Row(
                      icon: Icons.tune_rounded,
                      label: 'Pengaturan & Data',
                      onTap: () => context.push(AppRoute.appSettingsPath),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Opacity(opacity: 0.6, child: IbuDayaLogo(height: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final BadgeTone tone;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FeatureBadge(icon: icon, tone: tone, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.numeric(18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.labelSmall?.copyWith(fontSize: 10, letterSpacing: 0.4),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryDark),
      title: Text(label, style: text.titleSmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: text.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
