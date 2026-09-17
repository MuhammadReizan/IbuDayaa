import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/config/app_config.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.scaffoldAbout,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: IbuDayaLogo(height: 40, tagline: l10n.aboutTagline),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppConfig.versionLabel,
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.aboutDescription, style: text.bodyLarge),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            title: l10n.aboutNumbersSection,
            leadingIcon: Icons.calculate_outlined,
            child: Text(
              l10n.aboutNumbersBody,
              style: text.bodySmall?.copyWith(height: 1.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l10n.aboutDataStorageSection,
            leadingIcon: Icons.storage_rounded,
            child: Text(l10n.aboutDataStorageBody),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.aboutFooter(AppConfig.teamName),
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.delete_forever_rounded),
            label: Text(l10n.aboutResetDevice),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: l10n.aboutResetDeviceConfirmTitle,
                message: l10n.aboutResetDeviceConfirmBody,
                confirmLabel: l10n.actionDelete,
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              final done = await runAction(
                context,
                ref.read(actionsProvider).resetDevice,
                success: l10n.aboutResetDeviceSuccess,
              );
              if (done && context.mounted) context.go(Paths.welcome);
            },
          ),
        ],
      ),
    );
  }
}
