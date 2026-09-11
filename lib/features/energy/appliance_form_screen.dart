import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/models/models.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../shared/inputs.dart';
import '../shared/labels.dart';

class ApplianceFormScreen extends ConsumerStatefulWidget {
  const ApplianceFormScreen({super.key, this.existing});

  final Appliance? existing;

  @override
  ConsumerState<ApplianceFormScreen> createState() =>
      _ApplianceFormScreenState();
}

class _ApplianceFormScreenState extends ConsumerState<ApplianceFormScreen> {
  final _form = GlobalKey<FormState>();
  late String _kind = widget.existing?.kind ?? 'oven';
  late final _name = TextEditingController(
    text: widget.existing?.name ?? kApplianceKinds['oven']!.label,
  );
  late final _watts = TextEditingController(
    text: (widget.existing?.watts ?? kApplianceKinds['oven']!.watts)
        .round()
        .toString(),
  );
  late double _hours = widget.existing?.hoursPerDay ?? 2;
  late int _days = widget.existing?.daysPerWeek ?? 6;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _watts.dispose();
    super.dispose();
  }

  void _pickKind(String kind) {
    final preset = kApplianceKinds[kind]!;
    final wasPresetName = kApplianceKinds.values.any(
      (p) => p.label == _name.text,
    );
    setState(() {
      _kind = kind;
      if (_name.text.trim().isEmpty || wasPresetName) {
        _name.text = kind == 'other' ? '' : preset.label;
      }
      _watts.text = preset.watts.round().toString();
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref
          .read(actionsProvider)
          .saveAppliance(
            id: widget.existing?.id,
            name: _name.text.trim(),
            kind: _kind,
            watts: double.parse(_watts.text),
            hoursPerDay: _hours,
            daysPerWeek: _days,
          ),
      success: 'Alat tersimpan.',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.pop();
  }

  Future<void> _delete() async {
    final a = widget.existing!;
    final ok = await confirmDialog(
      context,
      title: 'Hapus ${a.name}?',
      message: 'Alat ini tidak lagi dihitung dalam analisis listrik.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runAction(
      context,
      () => ref.read(actionsProvider).deleteAppliance(a.id),
      success: 'Alat dihapus.',
    );
    if (done && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(appStateProvider).me;
    if (me == null) return const Scaffold();
    final text = Theme.of(context).textTheme;
    final watts = double.tryParse(_watts.text) ?? 0;
    final monthlyKwh = watts / 1000 * _hours * _days * (30 / 7);

    return AppScaffold(
      title: widget.existing == null ? 'Tambah Alat' : 'Ubah Alat',
      onBack: () => context.pop(),
      actions: [
        if (widget.existing != null)
          IconButton(
            tooltip: 'Hapus',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
      ],
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
            Text('Jenis alat', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final e in kApplianceKinds.entries)
                  ChoiceChip(
                    avatar: Icon(e.value.icon, size: 18),
                    label: Text(e.value.label),
                    selected: _kind == e.key,
                    onSelected: (_) => _pickKind(e.key),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Nama alat',
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Isi nama alat.' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Daya',
              controller: _watts,
              suffixText: 'watt',
              keyboardType: TextInputType.number,
              helper:
                  'Lihat stiker di belakang alat. Angka awal adalah ukuran umum.',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              validator: (v) {
                final w = double.tryParse(v ?? '');
                if (w == null || w <= 0) return 'Isi daya dalam watt.';
                if (w > 10000) return 'Terlalu besar untuk alat rumah tangga.';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text('Jam pakai per hari', style: text.titleSmall),
                ),
                Text('${decimalText(_hours)} jam', style: text.titleSmall),
              ],
            ),
            Slider(
              value: _hours,
              min: 0.5,
              max: 24,
              divisions: 47,
              label: '${decimalText(_hours)} jam',
              onChanged: (v) => setState(() => _hours = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Hari pakai per minggu', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (int d = 1; d <= 7; d++)
                  ChoiceChip(
                    label: Text('$d'),
                    selected: _days == d,
                    onSelected: (_) => setState(() => _days = d),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionCard(
              tone: CardTone.mint,
              child: Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Per bulan',
                      value: formatKwh(monthlyKwh),
                    ),
                  ),
                  Expanded(
                    child: StatTile(
                      label: 'Biaya',
                      value: formatRupiah(monthlyKwh * me.tariffIdrPerKwh),
                      qualifier: QualifierKind.estimasi,
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
