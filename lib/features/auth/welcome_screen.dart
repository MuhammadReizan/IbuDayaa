import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/paths.dart';
import '../../core/repositories/local/sample_seeder.dart';
import '../../core/state/actions.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top Left Decorative Pattern
          Positioned(
            top: 0,
            left: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  'assets/images/pattern1.webp',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Bottom Right Decorative Pattern
          Positioned(
            bottom: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  'assets/images/pattern2.webp',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Main Foreground Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: AppSpacing.screenH,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        // Language Switcher Top Right
                        Align(
                          alignment: Alignment.topRight,
                          child: _LanguageSwitcher(ref: ref),
                        ),

                        const Spacer(flex: 2),

                        // Logo Section
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/Logo IbuDaya.webp',
                                fit: BoxFit.contain,
                                width: 220,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.appTagline,
                                style: text.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 3),

                        // Action Buttons Section
                        PrimaryButton(
                          label: l10n.actionLogin,
                          onPressed: () => context.push(Paths.login),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SecondaryButton(
                          label: l10n.actionRegister,
                          onPressed: () => context.push(Paths.register),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: TextLinkButton(
                            label: l10n.welcomeTrySample,
                            icon: Icons.science_outlined,
                            onPressed: () => _openSample(context, ref),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSample(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(actionsProvider);
    if (!actions.sampleSeeded) {
      final l10n = AppLocalizations.of(context);
      final ok = await confirmDialog(
        context,
        title: l10n.welcomeSampleTitle,
        message: l10n.welcomeSampleBanner,
        confirmLabel: l10n.sampleConfirmLabel,
      );
      if (!ok || !context.mounted) return;
      final done = await runAction(context, actions.seedSample);
      if (!done || !context.mounted) return;
    }
    if (!context.mounted) return;

    final accounts = [
      (
        phone: SampleSeeder.adminPhone,
        name: 'Ibu Ratna',
        role: 'Admin koperasi',
      ),
      for (final m in SampleSeeder.members)
        (phone: m.phone, name: m.name, role: 'Anggota · ${m.business}'),
    ];
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            0,
            AppSpacing.gutter,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.welcomeLoginAs,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              InfoBanner(
                tone: InfoTone.warning,
                title: l10n.sampleTitle,
                message: l10n.sampleMessage,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final a in accounts) ...[
                TintedRow(
                  icon: a.role.startsWith('Admin')
                      ? Icons.admin_panel_settings_rounded
                      : Icons.storefront_rounded,
                  tone: a.role.startsWith('Admin')
                      ? PillTone.solar
                      : PillTone.success,
                  title: a.name,
                  subtitle: a.role,
                  onTap: () => Navigator.of(ctx).pop(a.phone),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    await runAction(context, () => actions.login(picked, SampleSeeder.pin));
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(resolvedLocaleProvider);
    final isEn = currentLocale.languageCode == 'en';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () =>
                ref.read(localeProvider.notifier).setLocale(const Locale('id')),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'ID',
                style: TextStyle(
                  fontWeight: !isEn ? FontWeight.bold : FontWeight.w500,
                  color: !isEn ? AppColors.primary : AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '|',
              style: TextStyle(color: AppColors.outline, fontSize: 14),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () =>
                ref.read(localeProvider.notifier).setLocale(const Locale('en')),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'EN',
                style: TextStyle(
                  fontWeight: isEn ? FontWeight.bold : FontWeight.w500,
                  color: isEn ? AppColors.primary : AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
