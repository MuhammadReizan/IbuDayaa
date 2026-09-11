import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
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

    return AppScaffold(
      title: 'Profil',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeader(me: me, coopName: data.cooperative?.name),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            child: Row(
              children: [
                Expanded(
                  child: StatTile(label: 'Bulan tercatat', value: '$months'),
                ),
                Expanded(
                  child: StatTile(label: 'Sesi hub', value: '$sessions'),
                ),
                Expanded(
                  child: StatTile(
                    label: 'Skor',
                    value: score == null ? '–' : '${score.score}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Usaha & energi'),
          _menu(
            context,
            Icons.receipt_long_rounded,
            'Catatan listrik',
            Paths.energy,
          ),
          _menu(context, Icons.kitchen_rounded, 'Alat usaha', Paths.appliances),
          _menu(
            context,
            Icons.event_available_rounded,
            'Jadwal Solar Hub',
            Paths.bookings,
          ),
          _menu(
            context,
            Icons.speed_rounded,
            'Skor Kredit Energi',
            Paths.score,
          ),
          _menu(
            context,
            Icons.account_balance_wallet_rounded,
            'Pembiayaan',
            Paths.loans,
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Akun'),
          _menu(
            context,
            Icons.person_outline_rounded,
            'Ubah profil & tarif listrik',
            Paths.profileEdit,
          ),
          _menu(
            context,
            Icons.lock_outline_rounded,
            'Ganti PIN',
            Paths.changePin,
          ),
          _menu(
            context,
            Icons.notifications_none_rounded,
            'Notifikasi',
            Paths.notifications,
          ),
          _menu(
            context,
            Icons.info_outline_rounded,
            'Tentang IbuDaya',
            Paths.about,
          ),
          const SizedBox(height: AppSpacing.lg),
          LogoutButton(ref: ref),
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
                      label: me.role.label,
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
  const LogoutButton({super.key, required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      label: 'Keluar',
      icon: Icons.logout_rounded,
      onPressed: () async {
        final ok = await confirmDialog(
          context,
          title: 'Keluar dari akun?',
          message: 'Data tetap tersimpan. Masuk lagi dengan nomor HP dan PIN.',
          confirmLabel: 'Keluar',
          destructive: true,
        );
        if (!ok || !context.mounted) return;
        await runAction(context, ref.read(actionsProvider).logout);
      },
    );
  }
}
