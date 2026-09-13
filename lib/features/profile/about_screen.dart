import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/config/app_config.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return AppScaffold(
      title: 'Tentang IbuDaya',
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          const Center(
            child: IbuDayaLogo(height: 40, tagline: 'Energi hemat, usaha kuat'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppConfig.versionLabel,
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'IbuDaya membantu usaha mikro milik perempuan mengelola biaya listrik, '
            'memakai Solar Hub koperasi, ikut arisan energi, dan mengajukan '
            'pinjaman usaha ke koperasinya.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            title: 'Dari mana angka-angkanya',
            leadingIcon: Icons.calculate_outlined,
            child: Text(
              '• Scan tagihan dibaca di HP (Google ML Kit), tidak dikirim ke '
              'internet. Anda selalu memeriksa angkanya sebelum disimpan.\n'
              '• Rincian per alat = watt × jam pakai × tarif Anda. Ini perkiraan.\n'
              '• Skor Kredit Energi memakai aturan tetap dengan 4 faktor yang '
              'terlihat di layar skor. Bukan kecerdasan buatan, bukan skor bank.\n'
              '• Keputusan pinjaman dibuat oleh admin koperasi.\n'
              '• CO₂ memakai asumsi 0,87 kg per kWh listrik PLN.',
              style: text.bodySmall?.copyWith(height: 1.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionCard(
            title: 'Penyimpanan data',
            leadingIcon: Icons.storage_rounded,
            child: Text(
              'Saat ini semua data tersimpan di HP ini saja. Versi berikutnya '
              'tersambung ke server koperasi agar anggota dan admin bisa saling '
              'melihat data dari HP masing-masing.',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Dibuat oleh tim ${AppConfig.teamName}.',
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Hapus semua data di HP ini'),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: 'Hapus semua data?',
                message:
                    'Semua akun, catatan listrik, arisan, pinjaman, dan pesan di '
                    'HP ini akan hilang dan tidak bisa dikembalikan.',
                confirmLabel: 'Hapus semua',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              final done = await runAction(
                context,
                ref.read(actionsProvider).resetDevice,
                success: 'Semua data di HP ini sudah dihapus.',
              );
              if (done && context.mounted) context.go(Paths.welcome);
            },
          ),
        ],
      ),
    );
  }
}
