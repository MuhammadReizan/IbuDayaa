import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/app_data_controller.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/energy.dart';

/// Publish spare capacity from the user's own hub slot to their circle.
class QuotaShareScreen extends ConsumerStatefulWidget {
  const QuotaShareScreen({super.key});

  @override
  ConsumerState<QuotaShareScreen> createState() => _QuotaShareScreenState();
}

class _QuotaShareScreenState extends ConsumerState<QuotaShareScreen> {
  static const _slots = [
    'Sabtu, 08.00–10.00',
    'Sabtu, 10.00–12.00',
    'Sabtu, 13.00–15.00',
    'Minggu, 08.00–10.00',
    'Minggu, 10.00–12.00',
  ];

  final _amount = TextEditingController(text: '2');
  final _note = TextEditingController();
  String _slot = _slots.first;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _amountValue =>
      double.tryParse(_amount.text.trim().replaceAll(',', '.'));

  Future<void> _publish() async {
    final kwh = _amountValue;
    if (kwh == null || kwh <= 0 || _saving) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(appDataProvider.notifier)
          .shareQuota(kwh: kwh, slotLabel: _slot, note: _note.text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      return;
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('${formatKwh(kwh)} ditawarkan ke grup Anda.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final kwh = _amountValue;

    return AppScaffold(
      title: 'Tawarkan Kuota',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Tawarkan ke Grup',
        loading: _saving,
        onPressed: (kwh != null && kwh > 0) ? _publish : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InfoBanner(
            tone: InfoTone.info,
            message:
                'Tawarkan sisa jatah pemakaian di slot Anda. Ini catatan '
                'kesepakatan — listriknya tetap dipakai langsung di Solar Hub '
                'oleh yang mengambil.',
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Jumlah yang ditawarkan', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final preset in const [1.0, 2.0, 3.0]) ...[
                Expanded(
                  child: _Chip(
                    kwh: preset,
                    selected: kwh == preset,
                    onTap: () => setState(
                      () => _amount.text = preset.toStringAsFixed(0),
                    ),
                  ),
                ),
                if (preset != 3.0) const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              suffixText: 'kWh',
              helperText: 'Atau isi jumlah lain di sini.',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Slot waktu', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            value: _slot,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.schedule_rounded, size: 20),
            ),
            items: [
              for (final s in _slots)
                DropdownMenuItem(value: s, child: Text(s)),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _slot = v);
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Catatan untuk anggota (opsional)', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _note,
            maxLines: 3,
            maxLength: 140,
            decoration: const InputDecoration(
              hintText: 'Misal: sisa jatah minggu ini, silakan yang butuh.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.kwh, required this.selected, required this.onTap});

  final double kwh;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: AppRadius.smBr,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              kwh.toStringAsFixed(0),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('kWh', style: text.labelSmall),
          ],
        ),
      ),
    );
  }
}
