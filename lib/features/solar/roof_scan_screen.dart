import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/logic/roof_estimator.dart';
import '../../core/models/models.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../../core/storage/device_services.dart';
import '../energy/scan_bill_screen.dart';
import '../shared/inputs.dart';

/// Radar Atap: photo of the roof for the record, then the member's own
/// measurements turned into a first estimate. The photo is not analysed.
class RoofScanScreen extends ConsumerStatefulWidget {
  const RoofScanScreen({super.key});

  @override
  ConsumerState<RoofScanScreen> createState() => _RoofScanScreenState();
}

class _RoofScanScreenState extends ConsumerState<RoofScanScreen> {
  int _step = 0;
  bool _copying = false;
  String? _photo;
  final _form = GlobalKey<FormState>();
  final _length = TextEditingController();
  final _width = TextEditingController();
  RoofOrientation _orientation = RoofOrientation.unknown;
  RoofShading _shading = RoofShading.none;
  bool _saved = false;
  bool _busy = false;

  @override
  void dispose() {
    _length.dispose();
    _width.dispose();
    super.dispose();
  }

  Future<void> _captured(String path) async {
    setState(() => _copying = true);
    String? kept;
    try {
      kept = await ref.read(photoStoreProvider).keep(path, folder: 'roofs');
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _copying = false;
      _photo = kept;
      _step = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) {
      return CaptureView(
        title: 'Radar Atap',
        hint: 'Foto atap yang ingin dipasang panel surya',
        frameAspect: 1.1,
        busy: _copying,
        busyLabel: 'Menyimpan foto…',
        onCaptured: _captured,
        tips: const ['Seluruh atap terlihat', 'Siang hari, cahaya cukup'],
        secondaryAction: TextButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text(
            'Lewati foto',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final coop = s.data.cooperative;
    final insight = s.data.insightOf(me.id);
    final text = Theme.of(context).textTheme;

    final length = parseDecimal(_length.text) ?? 0;
    final width = parseDecimal(_width.text) ?? 0;
    final estimate = estimateRoof(
      lengthM: length,
      widthM: width,
      orientation: _orientation,
      shading: _shading,
      tariffIdrPerKwh: me.tariffIdrPerKwh,
      costPerKwpIdr: coop?.solarCostPerKwpIdr ?? 15000000,
      monthlyUsageKwh: insight?.latest.kwh,
    );

    if (_step == 2) return _result(estimate, me, insight?.latest.kwh, text);

    return AppScaffold(
      title: 'Ukuran Atap',
      onBack: () => setState(() => _step = 0),
      bottomBar: PrimaryButton(
        label: 'Hitung potensi',
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          FocusScope.of(context).unfocus();
          setState(() {
            _step = 2;
            _saved = false;
          });
        },
      ),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_photo != null) ...[
              ClipRRect(
                borderRadius: AppRadius.cardBr,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.file(File(_photo!), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            const InfoBanner(
              tone: InfoTone.info,
              message:
                  'Ukur bagian atap yang bebas dipasang panel. Pakai meteran, '
                  'atau hitung langkah kaki: 1 langkah ≈ 0,7 meter.',
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _meterField('Panjang', _length)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _meterField('Lebar', _width)),
              ],
            ),
            if (length > 0 && width > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Luas ${decimalText(length * width)} m² · bisa dipakai ± '
                '${decimalText(estimate.usableAreaM2)} m²',
                style: text.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text('Atap menghadap ke mana?', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final o in RoofOrientation.values)
                  ChoiceChip(
                    label: Text(o.label),
                    selected: _orientation == o,
                    onSelected: (_) => setState(() => _orientation = o),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Apakah terhalang pohon atau bangunan?',
              style: text.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final sh in RoofShading.values)
                  ChoiceChip(
                    label: Text(sh.label),
                    selected: _shading == sh,
                    onSelected: (_) => setState(() => _shading = sh),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meterField(String label, TextEditingController c) => AppTextField(
    label: label,
    controller: c,
    suffixText: 'm',
    hint: '0',
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [decimalInput],
    validator: (v) {
      final x = parseDecimal(v ?? '');
      if (x == null || x <= 0) return 'Isi $label';
      if (x > 100) return 'Terlalu besar';
      return null;
    },
  );

  Widget _result(RoofEstimate e, Profile me, double? usage, TextTheme text) {
    final tone = switch (e.band) {
      'Sangat Layak' => PillTone.success,
      'Layak' => PillTone.success,
      'Cukup Layak' => PillTone.warning,
      _ => PillTone.danger,
    };
    final payback = e.paybackYears;

    return AppScaffold(
      title: 'Hasil Radar Atap',
      onBack: () => setState(() => _step = 1),
      bottomBar: PrimaryButton(
        label: _saved ? 'Tersimpan' : 'Simpan hasil',
        icon: _saved ? Icons.check_rounded : Icons.bookmark_add_rounded,
        loading: _busy,
        onPressed: _saved ? null : () => _save(e, me),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Potensi panel surya',
                        style: text.labelLarge?.copyWith(
                          color: AppColors.textOnDarkDim,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${e.kwp.toStringAsFixed(1).replaceAll('.', ',')} kWp',
                        style: AppTypography.numeric(34, color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      StatusPill(label: e.band, tone: tone),
                    ],
                  ),
                ),
                const BrandArt(motif: BrandArtMotif.roof, size: 84),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          NumberedSection(
            number: 1,
            title: 'Estimasi Produksi',
            child: SectionCard(
              child: Column(
                children: [
                  KeyValueRow(
                    label: 'Luas yang bisa dipakai',
                    value: '${decimalText(e.usableAreaM2)} m²',
                  ),
                  KeyValueRow(
                    label: 'Energi per bulan',
                    value: formatKwh(e.monthlyKwh),
                    emphasize: true,
                  ),
                  if (usage != null)
                    KeyValueRow(
                      label: 'Pemakaian Anda bulan terakhir',
                      value: formatKwh(usage),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          NumberedSection(
            number: 2,
            title: 'Estimasi Penghematan',
            child: SectionCard(
              tone: CardTone.mint,
              child: Column(
                children: [
                  KeyValueRow(
                    label: 'Hemat per bulan',
                    value: formatRupiah(e.monthlySavingIdr),
                    emphasize: true,
                    valueColor: AppColors.primaryDark,
                  ),
                  KeyValueRow(
                    label: 'Hemat per tahun',
                    value: formatRupiah(e.monthlySavingIdr * 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          NumberedSection(
            number: 3,
            title: 'Biaya & Balik Modal',
            child: SectionCard(
              child: Column(
                children: [
                  KeyValueRow(
                    label: 'Perkiraan biaya pasang',
                    value: formatRupiah(e.systemCostIdr),
                  ),
                  KeyValueRow(
                    label: 'Balik modal',
                    value: payback == null
                        ? '-'
                        : '± ${payback.toStringAsFixed(1).replaceAll('.', ',')} tahun',
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const VerificationNotice(),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Asumsi yang dipakai',
            child: Text(
              '• ${(kUsableRoofFraction * 100).round()}% luas atap bisa dipasang panel\n'
              '• ${kSquareMetersPerKwp.round()} m² atap per 1 kWp panel\n'
              '• ${kPeakSunHours.round()} jam matahari penuh per hari\n'
              '• ${(kPerformanceRatio * 100).round()}% energi tersisa setelah kabel & inverter\n'
              '• Faktor arah dan bayangan: ${(e.siteFactor * 100).round()}%\n'
              '• Biaya pasang ${formatRupiah(ref.read(appStateProvider).data.cooperative?.solarCostPerKwpIdr ?? 15000000)} per kWp (diatur koperasi)\n'
              '• Hemat hanya dihitung sampai sebesar pemakaian Anda, dengan tarif '
              '${formatRupiah(me.tariffIdrPerKwh)}/kWh',
              style: text.bodySmall?.copyWith(height: 1.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(RoofEstimate e, Profile me) async {
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref
          .read(actionsProvider)
          .saveRoofAssessment(
            RoofAssessment(
              id: '',
              userId: me.id,
              photoPath: _photo,
              lengthM: parseDecimal(_length.text)!,
              widthM: parseDecimal(_width.text)!,
              orientation: _orientation,
              shading: _shading,
              usableAreaM2: e.usableAreaM2,
              estKwp: e.kwp,
              estMonthlyKwh: e.monthlyKwh,
              estMonthlySavingIdr: e.monthlySavingIdr,
              estPaybackYears: e.paybackYears,
              band: e.band,
              createdAt: ref.read(clockProvider)(),
            ),
          ),
      success: 'Hasil Radar Atap tersimpan.',
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _saved = ok;
    });
    if (ok) context.pop();
  }
}
