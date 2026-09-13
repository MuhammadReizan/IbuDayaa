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
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Profil',
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
                          'Bulan tercatat',
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Sejak bergabung',
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
                          'Sesi hub',
                          style: text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Aktivitas di Solar Hub',
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
                          'Skor Kredit Energi',
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
                              const TextSpan(text: 'Kategori: '),
                              TextSpan(
                                text: score == null ? '–' : score.band.label,
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
