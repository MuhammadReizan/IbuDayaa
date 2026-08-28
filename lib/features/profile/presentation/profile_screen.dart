import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/demo/demo_providers.dart';
import '../../../core/demo/demo_scenario.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/money.dart';

/// SC-18: Profil (Settings + Impact)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DemoScenario scenario = ref.watch(currentScenarioProvider);
    final DemoUser user = scenario.user;
    final DemoImpactMetrics impact = scenario.impact;
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Profil',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Card
            SectionCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      user.displayName[0],
                      style: text.headlineMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName, style: text.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          user.role,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.phone,
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'ID: ${user.id}',
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Dampak Saya', style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            // Impact Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.5,
              children: [
                _ImpactCard(
                  title: 'Penghematan',
                  value: formatRupiah(impact.monthlySavingIdr),
                  icon: Icons.savings_outlined,
                  color: AppColors.success,
                ),
                _ImpactCard(
                  title: 'Emisi Berkurang',
                  value: '${impact.co2AvoidedKg.toStringAsFixed(1)} kg',
                  icon: Icons.eco_outlined,
                  color: AppColors.primary,
                ),
                _ImpactCard(
                  title: 'Energi Dibagikan',
                  value: '${impact.energySharedKwh.toStringAsFixed(1)} kWh',
                  icon: Icons.handshake_outlined,
                  color: AppColors.info,
                ),
                _ImpactCard(
                  title: 'Porsi Tenaga Surya',
                  value: '${impact.solarSharePct}%',
                  icon: Icons.wb_sunny_outlined,
                  color: AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Pengaturan', style: text.titleMedium),
            const SizedBox(height: AppSpacing.md),

            SectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Pengaturan Aplikasi'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Bantuan & FAQ'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Demo Reset
            SectionCard(
              title: 'Mode Demo',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Anda sedang menggunakan versi Demo Simulasi. Anda dapat mengembalikan '
                    'data skenario ke kondisi awal.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    label: 'Reset Data Demo',
                    onPressed: () {
                      resetDemo(ref);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Skenario demo dikembalikan ke awal.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
