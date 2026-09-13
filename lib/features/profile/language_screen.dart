import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/l10n/l10n.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(resolvedLocaleProvider);
    final text = Theme.of(context).textTheme;

    final options = [
      (code: 'id', label: l10n.languageId, flag: '🇮🇩'),
      (code: 'en', label: l10n.languageEn, flag: '🇬🇧'),
    ];

    return AppScaffold(
      title: l10n.languageTitle,
      onBack: () => Navigator.of(context).pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.languageSubtitle, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          for (final opt in options) ...[
            _LanguageOption(
              flag: opt.flag,
              label: opt.label,
              selected: currentLocale.languageCode == opt.code,
              onTap: () async {
                await ref
                    .read(localeProvider.notifier)
                    .setLocale(Locale(opt.code));
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: selected ? AppColors.primaryContainer : AppColors.surface,
      borderRadius: AppRadius.smBr,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smBr,
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smBr,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outlineSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: text.titleSmall?.copyWith(
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
