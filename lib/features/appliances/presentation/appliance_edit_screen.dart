import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/app_data_controller.dart';
import '../../../core/data/models.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/energy.dart';
import '../../../core/format/money.dart';
import 'appliances_screen.dart' show applianceIcon;

/// Add or correct one appliance.
///
/// Common appliances come with a starting wattage so the user has something
/// sensible to adjust rather than a blank field — the value is theirs to
/// correct from the label on the machine.
class ApplianceEditScreen extends ConsumerStatefulWidget {
  const ApplianceEditScreen({super.key, this.existing});

  final Appliance? existing;

  @override
  ConsumerState<ApplianceEditScreen> createState() =>
      _ApplianceEditScreenState();
}

class _ApplianceEditScreenState extends ConsumerState<ApplianceEditScreen> {
  static const _presets = <({String kind, String name, double watts})>[
    (kind: 'oven', name: 'Oven', watts: 1500),
    (kind: 'refrigerator', name: 'Kulkas', watts: 150),
    (kind: 'sewingMachine', name: 'Mesin Jahit', watts: 100),
    (kind: 'blender', name: 'Blender', watts: 350),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _watts;
  late double _hours;
  late int _days;
  late String _kind;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _watts = TextEditingController(
      text: e == null ? '' : e.watts.round().toString(),
    );
    _hours = e?.hoursPerDay ?? 2;
    _days = e?.daysPerWeek ?? 6;
    _kind = e?.kind ?? 'other';
  }

  @override
  void dispose() {
    _name.dispose();
    _watts.dispose();
    super.dispose();
  }

  void _applyPreset(({String kind, String name, double watts}) p) {
    setState(() {
      _kind = p.kind;
      _name.text = p.name;
      _watts.text = p.watts.round().toString();
    });
  }

  double? get _wattsValue =>
      double.tryParse(_watts.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(appDataProvider.notifier);
    final existing = widget.existing;

    try {
      if (existing == null) {
        await controller.addAppliance(
          name: _name.text.trim(),
          watts: _wattsValue!,
          hoursPerDay: _hours,
          daysPerWeek: _days,
          kind: _kind,
        );
      } else {
        await controller.updateAppliance(
          existing.copyWith(
            name: _name.text.trim(),
            watts: _wattsValue!,
            hoursPerDay: _hours,
            daysPerWeek: _days,
            kind: _kind,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      return;
    }
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tariff = ref.watch(profileProvider)?.tariffIdrPerKwh ?? 0;
    final watts = _wattsValue;

    final preview = (watts == null || watts <= 0)
        ? null
        : Appliance(
            id: 'preview',
            name: _name.text,
            watts: watts,
            hoursPerDay: _hours,
            daysPerWeek: _days,
            kind: _kind,
          );

    return AppScaffold(
      title: widget.existing == null ? 'Tambah Alat' : 'Ubah Alat',
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
            if (widget.existing == null) ...[
              Text('Pilih cepat', style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final p in _presets)
                    ActionChip(
                      avatar: Icon(applianceIcon(p.kind), size: 18),
                      label: Text(p.name),
                      onPressed: () => _applyPreset(p),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            Text('Nama alat', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Misal: Oven'),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Isi nama alat' : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Daya alat', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _watts,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                suffixText: 'watt',
                helperText: 'Lihat stiker atau buku panduan alat Anda.',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final parsed = double.tryParse(
                  (v ?? '').trim().replaceAll(',', '.'),
                );
                if (parsed == null || parsed <= 0) return 'Isi daya alat';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Dipakai ${_hours.toStringAsFixed(_hours % 1 == 0 ? 0 : 1)} jam '
              'per hari',
              style: text.titleSmall,
            ),
            Slider(
              value: _hours,
              min: 0.5,
              max: 16,
              divisions: 31,
              label: '${_hours.toStringAsFixed(_hours % 1 == 0 ? 0 : 1)} jam',
              onChanged: (v) => setState(() => _hours = v),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Dipakai $_days hari per minggu', style: text.titleSmall),
            Slider(
              value: _days.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$_days hari',
              onChanged: (v) => setState(() => _days = v.round()),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (preview != null)
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
                        'Perkiraan ${formatKwh(preview.monthlyKwh)} per bulan '
                        '≈ ${formatRupiah(preview.monthlyCostIdr(tariff))}',
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
