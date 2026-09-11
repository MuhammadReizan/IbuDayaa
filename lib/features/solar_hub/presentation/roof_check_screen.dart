import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';

/// A guided self-assessment of the user's roof.
///
/// This is **not** a measurement and not computer vision: the person answers
/// three questions they can check themselves, and the app applies a stated
/// rule to those answers. The result is a starting point for a conversation
/// with an installer, and says so.
class RoofCheckScreen extends ConsumerStatefulWidget {
  const RoofCheckScreen({super.key});

  @override
  ConsumerState<RoofCheckScreen> createState() => _RoofCheckScreenState();
}

enum _Orientation { eastWest, north, south, unknown }

enum _Shading { none, partial, heavy }

class _RoofCheckScreenState extends ConsumerState<RoofCheckScreen> {
  final _area = TextEditingController();
  _Orientation? _orientation;
  _Shading? _shading;
  bool _submitted = false;

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  double? get _areaValue =>
      double.tryParse(_area.text.trim().replaceAll(',', '.'));

  bool get _complete =>
      (_areaValue ?? 0) > 0 && _orientation != null && _shading != null;

  /// Points out of 100, from the three declared answers. The rule is shown to
  /// the user so the number is never a black box.
  int get _score {
    final area = _areaValue ?? 0;
    final areaPoints = (area / 40 * 40).clamp(0, 40).toDouble();
    final orientationPoints = switch (_orientation) {
      _Orientation.eastWest => 35.0,
      _Orientation.north => 28.0,
      _Orientation.south => 20.0,
      _ => 15.0,
    };
    final shadingPoints = switch (_shading) {
      _Shading.none => 25.0,
      _Shading.partial => 14.0,
      _ => 5.0,
    };
    return (areaPoints + orientationPoints + shadingPoints).round();
  }

  String get _band {
    final s = _score;
    if (s >= 80) return 'Sangat Menjanjikan';
    if (s >= 60) return 'Menjanjikan';
    if (s >= 40) return 'Cukup';
    return 'Kurang Cocok';
  }

  IconData get _bandIcon {
    final s = _score;
    if (s >= 80) return Icons.verified_rounded;
    if (s >= 60) return Icons.check_circle_outline_rounded;
    if (s >= 40) return Icons.info_outline_rounded;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Cek Kelayakan Atap',
      onBack: () => context.pop(),
      bottomBar: _submitted
          ? SecondaryButton(
              icon: Icons.refresh_rounded,
              label: 'Isi Ulang',
              onPressed: () => setState(() => _submitted = false),
            )
          : PrimaryButton(
              label: 'Lihat Hasil',
              onPressed: _complete
                  ? () => setState(() => _submitted = true)
                  : null,
            ),
      body: _submitted ? _result(text) : _form(text),
    );
  }

  Widget _form(TextTheme text) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const InfoBanner(
        tone: InfoTone.info,
        title: 'Anda yang mengukur, bukan aplikasi',
        message:
            'IbuDaya tidak bisa melihat atap Anda. Jawab tiga pertanyaan ini '
            'sesuai kenyataan, lalu aplikasi menerapkan aturan sederhana yang '
            'ditampilkan terbuka di hasilnya.',
      ),
      const SizedBox(height: AppSpacing.xl),

      Text('1. Perkiraan luas atap yang kosong', style: text.titleSmall),
      const SizedBox(height: AppSpacing.sm),
      TextField(
        controller: _area,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: const InputDecoration(
          suffixText: 'm²',
          helperText: 'Ukur kasar panjang × lebar bagian yang tidak terhalang.',
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: AppSpacing.xl),

      Text('2. Arah hadap atap', style: text.titleSmall),
      const SizedBox(height: AppSpacing.sm),
      _choice('Memanjang timur–barat', _Orientation.eastWest),
      _choice('Menghadap utara', _Orientation.north),
      _choice('Menghadap selatan', _Orientation.south),
      _choice('Tidak tahu', _Orientation.unknown),
      const SizedBox(height: AppSpacing.xl),

      Text('3. Ada yang menghalangi sinar matahari?', style: text.titleSmall),
      const SizedBox(height: AppSpacing.sm),
      _shadeChoice('Tidak ada halangan', _Shading.none),
      _shadeChoice('Sebagian terhalang pohon/bangunan', _Shading.partial),
      _shadeChoice('Banyak terhalang', _Shading.heavy),
    ],
  );

  Widget _choice(String label, _Orientation value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: SelectableTile(
      icon: Icons.explore_outlined,
      label: label,
      selected: _orientation == value,
      onTap: () => setState(() => _orientation = value),
    ),
  );

  Widget _shadeChoice(String label, _Shading value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: SelectableTile(
      icon: Icons.wb_shade_outlined,
      label: label,
      selected: _shading == value,
      onTap: () => setState(() => _shading = value),
    ),
  );

  Widget _result(TextTheme text) {
    final area = _areaValue ?? 0;
    return Column(
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
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(_bandIcon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Kelayakan Awal',
                style: text.labelSmall?.copyWith(
                  color: AppColors.textOnDarkDim,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _band,
                style: text.headlineSmall?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const QualifierLabel(QualifierKind.estimasiAwal, onDark: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        const InfoBanner(
          tone: InfoTone.warning,
          message:
              'Ini bukan hasil pengukuran. Sebelum pemasangan, atap tetap '
              'harus diperiksa langsung oleh teknisi di lokasi.',
        ),
        const SizedBox(height: AppSpacing.xl),

        Text('Cara hasil ini dihitung', style: text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          child: Column(
            children: [
              _row('Luas atap yang Anda isi', '${area.toStringAsFixed(0)} m²'),
              const Divider(height: AppSpacing.lg),
              _row('Arah hadap', switch (_orientation) {
                _Orientation.eastWest => 'Timur–barat (terbaik)',
                _Orientation.north => 'Utara',
                _Orientation.south => 'Selatan',
                _ => 'Tidak diketahui',
              }),
              const Divider(height: AppSpacing.lg),
              _row('Halangan sinar', switch (_shading) {
                _Shading.none => 'Tidak ada',
                _Shading.partial => 'Sebagian',
                _ => 'Banyak',
              }),
              const Divider(height: AppSpacing.lg),
              _row('Nilai kelayakan', '$_score dari 100', strong: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Aturannya: luas atap sampai 40 poin, arah hadap sampai 35 poin, '
          'dan bebas halangan sampai 25 poin. Tidak ada model atau tebakan di '
          'balik angka ini.',
          style: text.bodySmall,
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: text.bodySmall)),
        const SizedBox(width: AppSpacing.md),
        Text(
          value,
          style: strong
              ? text.titleSmall?.copyWith(color: AppColors.primaryDark)
              : text.titleSmall,
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}
