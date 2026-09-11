import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/paths.dart';
import '../../core/repositories/local/sample_seeder.dart';
import '../../core/state/actions.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: AppSpacing.screenH,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    const Center(
                      child: IbuDayaLogo(
                        height: 36,
                        tagline: 'Energi hemat, usaha kuat',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Center(
                      child: BrandArt(
                        motif: BrandArtMotif.community,
                        size: 190,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Kelola listrik usaha bersama koperasi',
                      style: text.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _Point(
                      icon: Icons.document_scanner_rounded,
                      text: 'Scan tagihan PLN, lihat alat yang paling boros',
                    ),
                    const _Point(
                      icon: Icons.solar_power_rounded,
                      text: 'Pesan jadwal pakai Solar Hub koperasi',
                    ),
                    const _Point(
                      icon: Icons.groups_rounded,
                      text: 'Arisan energi dan pinjaman usaha dari koperasi',
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Masuk',
                      onPressed: () => context.push(Paths.login),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(
                      label: 'Daftar',
                      onPressed: () => context.push(Paths.register),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextLinkButton(
                      label: 'Coba dengan data contoh',
                      icon: Icons.science_outlined,
                      onPressed: () => _openSample(context, ref),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSample(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(actionsProvider);
    if (!actions.sampleSeeded) {
      final ok = await confirmDialog(
        context,
        title: 'Tambah data contoh?',
        message:
            'Aplikasi akan membuat "Koperasi Energi Melati" berisi 1 admin dan '
            '4 anggota dengan catatan listrik, arisan, dan pengajuan pinjaman '
            'rekaan. Semua angka di dalamnya bukan data asli. Anda bisa '
            'menghapusnya kapan saja dari menu Tentang.',
        confirmLabel: 'Tambahkan',
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
              Text('Masuk sebagai', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              const InfoBanner(
                tone: InfoTone.warning,
                title: 'Data contoh',
                message:
                    'Semua akun di bawah memakai PIN ${SampleSeeder.pin}. '
                    'Isinya rekaan untuk mencoba aplikasi.',
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

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          FeatureBadge(icon: icon, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
