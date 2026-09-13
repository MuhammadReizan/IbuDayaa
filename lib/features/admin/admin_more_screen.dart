import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/paths.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../profile/profile_screen.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;

    Widget item(
      IconData icon,
      String title,
      String path, {
      String? subtitle,
      int badge = 0,
      PillTone tone = PillTone.success,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TintedRow(
        icon: icon,
        tone: tone,
        title: title,
        subtitle: subtitle,
        trailing: badge > 0
            ? StatusPill(label: '$badge', tone: PillTone.danger)
            : const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
        onTap: () => context.push(path),
      ),
    );

    return AppScaffold(
      title: l10n.scaffoldAdminOther,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeader(me: me, coopName: data.cooperative?.name),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.adminSectionManage),
          item(
            Icons.payments_rounded,
            l10n.adminPaymentsMenu,
            Paths.adminPayments,
            badge: data.pendingPayments.length,
            tone: PillTone.warning,
          ),
          item(
            Icons.groups_rounded,
            l10n.adminArisanMenu,
            Paths.adminArisan,
            subtitle:
                '${data.groups.length} ${l10n.arisanGroupName.toLowerCase()}',
          ),
          item(
            Icons.solar_power_rounded,
            l10n.adminHubMenu,
            Paths.adminHub,
            tone: PillTone.solar,
          ),
          item(
            Icons.campaign_rounded,
            l10n.adminAnnounceMenu,
            Paths.adminAnnounce,
            tone: PillTone.info,
          ),
          item(
            Icons.chat_bubble_outline_rounded,
            l10n.adminMessagesMenu,
            Paths.adminMessages,
            badge: data.unreadMessagesOf(me),
            tone: PillTone.info,
          ),
          item(
            Icons.tune_rounded,
            l10n.adminSettingsMenu,
            Paths.adminSettings,
            subtitle: l10n.adminSettingsSubtitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: l10n.adminSectionAccount),
          item(
            Icons.person_outline_rounded,
            l10n.adminEditProfile,
            Paths.profileEdit,
          ),
          item(
            Icons.lock_outline_rounded,
            l10n.adminChangePin,
            Paths.changePin,
          ),
          item(
            Icons.notifications_none_rounded,
            l10n.scaffoldNotifications,
            Paths.notifications,
            badge: data.unreadNotificationsOf(me.id),
          ),
          item(
            Icons.language_rounded,
            l10n.profileMenuLanguage,
            Paths.language,
          ),
          item(Icons.info_outline_rounded, l10n.profileMenuAbout, Paths.about),
          const SizedBox(height: AppSpacing.lg),
          LogoutButton(ref: ref, l10n: l10n),
        ],
      ),
    );
  }
}
