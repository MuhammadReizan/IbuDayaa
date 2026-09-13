import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/energy_insights.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../credit_score/application/credit_score_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final now = ref.read(clockProvider)();
    final score = data.scoreOf(
      me.id,
      now,
      ref.read(creditScoringEngineProvider),
    );
    final months = monthlyUsage(data.recordsOf(me.id)).length;
    final sessions = data
        .bookingsOf(me.id)
        .where((b) => b.status == BookingStatus.completed)
        .length;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.profileTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeader(me: me, coopName: data.cooperative?.name),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.xs,
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '$months',
                          style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.profileMonthsRecorded,
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          l10n.profileSinceJoined,
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, color: AppColors.outlineSubtle),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.infoContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: AppColors.info,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '$sessions',
                          style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.profileHubSessions,
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          l10n.profileHubActivities,
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, color: AppColors.outlineSubtle),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.star_outline_rounded,
                            color: AppColors.secondaryDark,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          score == null ? '–' : '${score.score}',
                          style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.profileEnergyCredit,
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: l10n.profileCategory),
                              TextSpan(
                                text: score == null
                                    ? '–'
                                    : score.band.localizedLabel(l10n),
                                style: TextStyle(
                                  color: score == null
                                      ? AppColors.textTertiary
                                      : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.profileSectionBusiness),
          _menu(
            context,
            Icons.receipt_long_rounded,
            l10n.profileMenuEnergy,
            Paths.energy,
          ),
          _menu(
            context,
            Icons.kitchen_rounded,
            l10n.profileMenuAppliances,
            Paths.appliances,
          ),
          _menu(
            context,
            Icons.event_available_rounded,
            l10n.profileMenuSolarSchedule,
            Paths.bookings,
          ),
          _menu(
            context,
            Icons.speed_rounded,
            l10n.profileMenuScore,
            Paths.score,
          ),
          _menu(
            context,
            Icons.account_balance_wallet_rounded,
            l10n.profileMenuLoans,
            Paths.loans,
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: l10n.profileSectionAccount),
          _menu(
            context,
            Icons.person_outline_rounded,
            l10n.profileMenuEditProfile,
            Paths.profileEdit,
          ),
          _menu(
            context,
            Icons.lock_outline_rounded,
            l10n.profileMenuChangePin,
            Paths.changePin,
          ),
          _menu(
            context,
            Icons.notifications_none_rounded,
            l10n.profileMenuNotifications,
            Paths.notifications,
          ),
          _menu(
            context,
            Icons.language_rounded,
            l10n.profileMenuLanguage,
            Paths.language,
          ),
          _menu(
            context,
            Icons.info_outline_rounded,
            l10n.profileMenuAbout,
            Paths.about,
          ),
          const SizedBox(height: AppSpacing.lg),
          LogoutButton(ref: ref, l10n: l10n),
        ],
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    IconData icon,
    String label,
    String path,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: TintedRow(
      icon: icon,
      tone: PillTone.success,
      title: label,
      onTap: () => context.push(path),
    ),
  );
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.me, this.coopName});

  final Profile me;
  final String? coopName;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return HeroCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: MemberAvatar(name: me.fullName, size: 60),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me.fullName,
                  style: text.titleLarge?.copyWith(color: Colors.white),
                ),
                if (me.businessName.isNotEmpty)
                  Text(
                    me.businessName,
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${me.displayPhone} · ${me.city}',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textOnDarkDim,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusPill(
                      label: me.role.localizedLabel(l10n),
                      tone: me.isAdmin ? PillTone.solar : PillTone.success,
                    ),
                    if (coopName != null)
                      StatusPill(label: coopName!, tone: PillTone.neutral),
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

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key, required this.ref, required this.l10n});

  final WidgetRef ref;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      label: l10n.profileLogout,
      icon: Icons.logout_rounded,
      onPressed: () async {
        final ok = await confirmDialog(
          context,
          title: l10n.profileLogoutTitle,
          message: l10n.profileLogoutMessage,
          confirmLabel: l10n.profileLogoutConfirm,
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        await runAction(context, ref.read(actionsProvider).logout);
      },
    );
  }
}
