import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/app_data_controller.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/data/models.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';

/// Record (or correct) one month's PLN bill.
///
/// Two numbers off the paper bill are enough: total kWh and total rupiah.
/// Everything downstream — cost per appliance, savings, the score — is derived
/// from these, so the form stays deliberately short.
class BillAddScreen extends ConsumerStatefulWidget {
  const BillAddScreen({super.key, this.existing});

  final Bill? existing;

  @override
  ConsumerState<BillAddScreen> createState() => _BillAddScreenState();
}

class _BillAddScreenState extends ConsumerState<BillAddScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kwh;
  late final TextEditingController _total;
  late DateTime _month;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _kwh = TextEditingController(text: e == null ? '' : _trim(e.kwh));
    _total = TextEditingController(
      text: e == null ? '' : e.totalIdr.toString(),
    );
    final now = DateTime.now();
    _month = e?.periodMonth ?? DateTime(now.year, now.month);
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _kwh.dispose();
    _total.dispose();
    super.dispose();
  }

  double? get _kwhValue =>
      double.tryParse(_kwh.text.trim().replaceAll(',', '.'));
  int? get _totalValue =>
      int.tryParse(_total.text.trim().replaceAll(RegExp(r'[^0-9]'), ''));

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Pilih bulan tagihan',
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(appDataProvider.notifier);
    final month = _month;
    final kwh = _kwhValue!;
    final total = _totalValue!;

    // Leave the form first, then write. Mutating while this route is still on
    // top leaves the screens underneath with a paused, stale subscription that
    // Riverpod then flushes mid-build.
    context.pop();

    try {
      await controller.addBill(periodMonth: month, kwh: kwh, totalIdr: total);
      messenger.showSnackBar(
        SnackBar(content: Text('Tagihan ${formatMonthYear(month)} tersimpan.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final kwh = _kwhValue;
    final total = _totalValue;
    final bool canPreview = kwh != null && kwh > 0 && total != null;

    return AppScaffold(
      title: widget.existing == null ? 'Catat Tagihan' : 'Ubah Tagihan',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Simpan',
        loading: _saving,
        onPressed: _save,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoBanner(
              tone: InfoTone.info,
              message:
                  'Ambil dua angka dari struk PLN Anda: total pemakaian (kWh) '
                  'dan total yang dibayar.',
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Bulan tagihan', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SelectableTile(
              icon: Icons.calendar_month_outlined,
              label: formatMonthYear(_month),
              selected: false,
              onTap: _pickMonth,
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Total pemakaian', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _kwh,
              autofocus: widget.existing == null,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                suffixText: 'kWh',
                hintText: 'Misal: 128',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final parsed = double.tryParse(
                  (v ?? '').trim().replaceAll(',', '.'),
                );
                if (parsed == null || parsed <= 0) {
                  return 'Isi jumlah kWh dari struk';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Total dibayar', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _total,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: 'Misal: 185000',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final parsed = int.tryParse(
                  (v ?? '').trim().replaceAll(RegExp(r'[^0-9]'), ''),
                );
                if (parsed == null || parsed <= 0) {
                  return 'Isi total tagihan';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            if (canPreview)
              SectionCard(
                tone: CardTone.mint,
                child: Row(
                  children: [
                    const Icon(
                      Icons.calculate_outlined,
                      size: 20,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Tarif efektif bulan ini: '
                        '${formatRupiah((total / kwh).round())} per kWh',
                        style: text.bodySmall?.copyWith(
                          color: AppColors.primaryDarker,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
