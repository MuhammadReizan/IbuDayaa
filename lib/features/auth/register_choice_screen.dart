import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/paths.dart';

class RegisterChoiceScreen extends StatelessWidget {
  const RegisterChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AppScaffold(
      title: l10n.registerTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.registerPrompt, style: text.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.registerSubtitle, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          _RoleCard(
            motif: BrandArtMotif.community,
            title: l10n.registerAsMember,
            body: l10n.registerMemberBody,
            cta: l10n.registerMemberCta,
            onTap: () => context.push(Paths.registerMember),
          ),
          const SizedBox(height: AppSpacing.lg),
          _RoleCard(
            motif: BrandArtMotif.finance,
            title: l10n.registerAsAdmin,
            body: l10n.registerAdminBody,
            cta: l10n.registerAdminCta,
            tone: CardTone.solar,
            onTap: () => context.push(Paths.registerAdmin),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.registerHaveAccount, style: text.bodyMedium),
              TextLinkButton(
                label: l10n.actionLogin,
                onPressed: () => context.pushReplacement(Paths.login),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.motif,
    required this.title,
    required this.body,
    required this.cta,
    required this.onTap,
    this.tone = CardTone.mint,
  });

  final BrandArtMotif motif;
  final String title;
  final String body;
  final String cta;
  final VoidCallback onTap;
  final CardTone tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      tone: tone,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandArt(motif: motif, size: 72),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: text.bodySmall),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        cta,
                        style: text.labelLarge?.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
