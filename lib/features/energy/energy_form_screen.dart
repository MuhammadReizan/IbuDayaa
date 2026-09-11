import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/row.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../shared/inputs.dart';

/// Values to prefill the form with — from a scan, or nothing.
@immutable
class EnergyDraft {
  const EnergyDraft({
    this.kind = EnergyKind.postpaid,
    this.periodMonth,
    this.kwh,
    this.totalIdr,
    this.customerId,
    this.photoPath,
    this.source = RecordSource.manual,
    this.rawText,
    this.readFailed = false,
  });

  final EnergyKind kind;
  final DateTime? periodMonth;
  final double? kwh;
  final int? totalIdr;
  final String? customerId;
  final String? photoPath;
  final RecordSource source;
  final String? rawText;
  final bool readFailed;
}

class EnergyFormScreen extends ConsumerStatefulWidget {
  const EnergyFormScreen({super.key, this.draft});

  final EnergyDraft? draft;

  @override
  ConsumerState<EnergyFormScreen> createState() => _EnergyFormScreenState();
}

class _EnergyFormScreenState extends ConsumerState<EnergyFormScreen> {
  final _form = GlobalKey<FormState>();
  late EnergyKind _kind = widget.draft?.kind ?? EnergyKind.postpaid;
  late DateTime _month;
  late final _kwh = TextEditingController(
    text: widget.draft?.kwh == null ? '' : decimalText(widget.draft!.kwh!),
  );
  late final _total = TextEditingController(
    text: widget.draft?.totalIdr == null
        ? ''
        : thousands(widget.draft!.totalIdr!),
  );
  late final _customer = TextEditingController(
    text: widget.draft?.customerId ?? '',
  );
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    final m = widget.draft?.periodMonth;
    final earliest = DateTime(now.year, now.month - 11);
    _month = m == null || m.isBefore(earliest) || m.isAfter(monthOf(now))
        ? monthOf(now)
        : monthOf(m);
  }

  @override
  void dispose() {
    _kwh.dispose();
    _total.dispose();
    _customer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref
          .read(actionsProvider)
          .saveRecord(
            kind: _kind,
            periodMonth: _month,
            kwh: parseDecimal(_kwh.text)!,
            totalIdr: parseDigits(_total.text)!,
            customerId: _customer.text.trim().isEmpty
                ? null
                : _customer.text.trim(),
            photoPath: widget.draft?.photoPath,
            source: widget.draft?.source ?? RecordSource.manual,
          ),
      success: 'Catatan listrik tersimpan.',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.pushReplacement(Paths.energyAnalysis);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final text = Theme.of(context).textTheme;
    final draft = widget.draft;
    final now = ref.read(clockProvider)();
    final fromScan = draft?.source == RecordSource.scan;

    final kwh = parseDecimal(_kwh.text);
    final total = parseDigits(_total.text);
    final perKwh = kwh != null && kwh > 0 && total != null ? total / kwh : null;
    final suspicious =
        perKwh != null &&
        (perKwh < me.tariffIdrPerKwh * 0.6 ||
            perKwh > me.tariffIdrPerKwh * 1.6);
    final replacing =
        _kind == EnergyKind.postpaid &&
        s.data.energyRecords.any(
          (r) =>
              r.userId == me.id &&
              r.kind == EnergyKind.postpaid &&
              sameMonth(r.periodMonth, _month),
        );

    return AppScaffold(
      title: fromScan ? 'Hasil Scan' : 'Catat Listrik',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Simpan',
        loading: _busy,
        onPressed: _save,
      ),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fromScan) ...[
              _ScanSummary(draft: draft!),
              const SizedBox(height: AppSpacing.lg),
            ],
            SegmentedButton<EnergyKind>(
              segments: const [
                ButtonSegment(
                  value: EnergyKind.postpaid,
                  label: Text('Tagihan'),
                  icon: Icon(Icons.receipt_long_rounded),
                ),
                ButtonSegment(
                  value: EnergyKind.token,
                  label: Text('Token'),
                  icon: Icon(Icons.bolt_rounded),
                ),
              ],
              selected: {_kind},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _kind = v.first),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _kind == EnergyKind.postpaid
                  ? 'Pascabayar: tagihan bulanan PLN.'
                  : 'Prabayar: struk pembelian token. Beberapa token dalam '
                        'sebulan dijumlahkan.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _kind == EnergyKind.postpaid
                  ? 'Bulan tagihan'
                  : 'Bulan pembelian',
              style: text.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<DateTime>(
              value: _month,
              items: [
                for (int i = 0; i < 12; i++)
                  DropdownMenuItem(
                    value: DateTime(now.year, now.month - i),
                    child: Text(
                      monthYearLabel(DateTime(now.year, now.month - i)),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _month = v ?? _month),
            ),
            if (replacing) ...[
              const SizedBox(height: AppSpacing.sm),
              const InfoBanner(
                tone: InfoTone.warning,
                message:
                    'Tagihan bulan ini sudah tercatat. Menyimpan akan menggantinya.',
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: _kind == EnergyKind.postpaid
                  ? 'Pemakaian listrik'
                  : 'Jumlah kWh token',
              controller: _kwh,
              hint: 'Contoh: 128',
              suffixText: 'kWh',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                decimalInput,
                LengthLimitingTextInputFormatter(8),
              ],
              helper: _kind == EnergyKind.postpaid
                  ? 'Lihat "Pemakaian" atau selisih Stand Meter.'
                  : 'Lihat "Jml kWh" di struk.',
              validator: (v) {
                final x = parseDecimal(v ?? '');
                if (x == null || x <= 0) return 'Isi jumlah kWh.';
                if (x > 20000) return 'Angka terlalu besar. Periksa lagi.';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: _kind == EnergyKind.postpaid
                  ? 'Total tagihan'
                  : 'Total bayar',
              controller: _total,
              hint: 'Contoh: 185.000',
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              inputFormatters: [
                ThousandsFormatter(),
                LengthLimitingTextInputFormatter(13),
              ],
              validator: (v) {
                final x = parseDigits(v ?? '');
                if (x == null || x < 1000) return 'Isi total rupiah.';
                return null;
              },
            ),
            if (_kind == EnergyKind.postpaid) ...[
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'ID pelanggan (boleh kosong)',
                controller: _customer,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
              ),
            ],
            if (perKwh != null) ...[
              const SizedBox(height: AppSpacing.lg),
              InfoBanner(
                tone: suspicious ? InfoTone.warning : InfoTone.success,
                title: 'Harga per kWh: ${formatRupiah(perKwh)}',
                message: suspicious
                    ? 'Jauh dari tarif Anda (${formatRupiah(me.tariffIdrPerKwh)}/kWh). '
                          'Periksa lagi kWh dan totalnya.'
                    : 'Sesuai dengan tarif Anda (${formatRupiah(me.tariffIdrPerKwh)}/kWh).',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanSummary extends StatelessWidget {
  const _ScanSummary({required this.draft});

  final EnergyDraft draft;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final found = [
      if (draft.kwh != null) 'kWh',
      if (draft.totalIdr != null) 'total',
      if (draft.periodMonth != null) 'bulan',
    ];
    final photo = draft.photoPath;

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photo != null)
                ClipRRect(
                  borderRadius: AppRadius.xsBr,
                  child: Image.file(
                    File(photo),
                    width: 64,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const SizedBox(width: 64, height: 84),
                  ),
                ),
              if (photo != null) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(
                      label: draft.readFailed
                          ? 'Tidak terbaca'
                          : found.isEmpty
                          ? 'Angka tidak ditemukan'
                          : 'Terbaca: ${found.join(', ')}',
                      tone: draft.readFailed || found.isEmpty
                          ? PillTone.warning
                          : PillTone.success,
                      icon: draft.readFailed || found.isEmpty
                          ? Icons.help_outline_rounded
                          : Icons.document_scanner_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      draft.readFailed || found.isEmpty
                          ? 'Isi angkanya sendiri dari foto tagihan.'
                          : 'Periksa setiap angka di bawah. Perbaiki jika ada yang '
                                'salah baca.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((draft.rawText ?? '').trim().isNotEmpty)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Lihat teks yang terbaca', style: text.labelLarge),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: AppRadius.xsBr,
                    ),
                    child: SelectableText(
                      draft.rawText!.trim(),
                      style: text.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
