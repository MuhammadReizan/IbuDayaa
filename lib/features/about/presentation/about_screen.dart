import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/brand.dart';
import '../../../core/config/app_config.dart';
import '../../../core/data/insights.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';

/// What this app is, what it does, and — just as importantly — what it does
/// not do. This screen is the place someone goes when they want to know
/// whether to trust a number they saw.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _pillars = [
    (
      icon: Icons.solar_power_outlined,
      title: 'Solar Hub Komunitas',
      body:
          'Catat energi yang Anda ambil dari instalasi surya bersama, lalu '
          'lihat nilainya dalam rupiah dan emisi yang dihindari.',
    ),
    (
      icon: Icons.insights_outlined,
      title: 'Skor Energi',
      body:
          'Skor internal dari kebiasaan mencatat, membayar, dan berusaha — '
          'untuk perempuan yang belum punya riwayat bank.',
    ),
    (
      icon: Icons.groups_2_outlined,
      title: 'Arisan Energi',
      body:
          'Buku kas arisan yang terbuka: iuran, giliran, dan berbagi kuota '
          'energi antaranggota, tercatat rapi.',
    ),
  ];

  static const _notThis = [
    'Tidak menyalurkan, menawarkan, atau menyetujui pinjaman. Kalkulator '
        'cicilan hanya alat hitung untuk membandingkan tawaran dari lembaga '
        'berizin OJK.',
    'Tidak memakai kecerdasan buatan. Semua angka adalah aritmetika biasa atas '
        'data yang Anda masukkan, dan rumusnya ditampilkan.',
    'Tidak membaca meteran atau tagihan Anda secara otomatis. Anda yang '
        'mencatat; aplikasi yang menghitung.',
    'Tidak memindahkan listrik. Berbagi kuota adalah catatan kesepakatan '
        'antaranggota, bukan transfer energi.',
    'Tidak mengirim data ke server mana pun. Tidak ada akun, tidak ada '
        'sinkronisasi, dan aplikasi bekerja penuh tanpa internet.',
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Tentang IbuDaya',
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: AppSpacing.hero,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: AppRadius.lgBr,
              boxShadow: AppShadows.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IbuDayaLogo(height: 26, variant: BrandVariant.onDark),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Pencatat energi dan arisan untuk usaha mikro yang dipimpin '
                  'perempuan. Dibuat supaya biaya listrik usaha Anda bisa '
                  'dilihat, dipahami, dan ditekan.',
                  style: text.bodyMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: AppRadius.pillBr,
                  ),
                  child: Text(
                    'SDG 11 — Sustainable Cities and Communities',
                    style: text.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tujuan utama adalah SDG 11. IbuDaya juga menyentuh SDG 5 '
            '(kesetaraan gender), SDG 7 (energi bersih), dan SDG 8 '
            '(pekerjaan layak) sebagai area dampak terkait.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Tiga Pilar', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final p in _pillars) ...[
            SectionCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FeatureBadge(icon: p.icon, tone: BadgeTone.mint, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title, style: text.titleSmall),
                        const SizedBox(height: 2),
                        Text(p.body, style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),

          Text('Yang IbuDaya Tidak Lakukan', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('Supaya Anda tahu persis batasnya:', style: text.bodySmall),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < _notThis.length; i++) ...[
                  if (i > 0) const Divider(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.block_rounded,
                          size: 15,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(_notThis[i], style: text.bodySmall)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Angka yang Dipakai', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            tone: CardTone.mint,
            child: Text(
              'Emisi yang dihindari dihitung dengan asumsi '
              '$kGridEmissionFactorKgPerKwh kg CO₂ per kWh listrik jaringan. '
              'Ini angka rujukan umum untuk jaringan Jawa–Bali, bukan hasil '
              'pengukuran di lokasi Anda. Biaya dihitung dari tarif listrik '
              'yang Anda isi sendiri di Pengaturan.',
              style: text.bodySmall?.copyWith(color: AppColors.primaryDarker),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetaRow(label: 'Tim', value: AppConfig.teamName),
                const Divider(height: AppSpacing.lg),
                _MetaRow(label: 'Versi', value: AppConfig.version),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Opacity(
              opacity: 0.5,
              child: Text('© 2026 Baswara Musi', style: text.labelSmall),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(label, style: text.bodySmall),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(value, style: text.titleSmall, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
