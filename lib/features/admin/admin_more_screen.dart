import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/paths.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../profile/profile_screen.dart';

class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      title: 'Lainnya',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeader(me: me, coopName: data.cooperative?.name),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Kelola koperasi'),
          item(
            Icons.payments_rounded,
            'Konfirmasi setoran arisan',
            Paths.adminPayments,
            badge: data.pendingPayments.length,
            tone: PillTone.warning,
          ),
          item(
            Icons.groups_rounded,
            'Grup arisan',
            Paths.adminArisan,
            subtitle: '${data.groups.length} grup',
          ),
          item(
            Icons.solar_power_rounded,
            'Solar Hub & slot',
            Paths.adminHub,
            tone: PillTone.solar,
          ),
          item(
            Icons.campaign_rounded,
            'Kirim pengumuman',
            Paths.adminAnnounce,
            tone: PillTone.info,
          ),
          item(
            Icons.chat_bubble_outline_rounded,
            'Pesan',
            Paths.adminMessages,
            badge: data.unreadMessagesOf(me),
            tone: PillTone.info,
          ),
          item(
            Icons.tune_rounded,
            'Pengaturan koperasi & pinjaman',
            Paths.adminSettings,
            subtitle: 'Kode undangan, plafon, jasa, tenor, kuota',
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Akun'),
          item(Icons.person_outline_rounded, 'Ubah profil', Paths.profileEdit),
          item(Icons.lock_outline_rounded, 'Ganti PIN', Paths.changePin),
          item(
            Icons.notifications_none_rounded,
            'Notifikasi',
            Paths.notifications,
            badge: data.unreadNotificationsOf(me.id),
          ),
          item(Icons.info_outline_rounded, 'Tentang IbuDaya', Paths.about),
          const SizedBox(height: AppSpacing.lg),
          LogoutButton(ref: ref),
        ],
      ),
    );
  }
}
