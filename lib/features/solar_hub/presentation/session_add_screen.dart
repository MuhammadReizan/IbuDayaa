import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/app_data_controller.dart';
import '../../../core/data/derived_providers.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/energy.dart';
import '../../../core/format/money.dart';
import '../../appliances/presentation/appliances_screen.dart'
    show applianceIcon;

/// Log one run on the shared hub.
///
/// Picking a declared appliance and the hours it ran computes the kWh from its
/// wattage, so the user never has to do the arithmetic — but they can override
/// the result if they metered it themselves.
class SessionAddScreen extends ConsumerStatefulWidget {
  const SessionAddScreen({super.key});

  @override
  ConsumerState<SessionAddScreen> createState() => _SessionAddScreenState();
}

class _SessionAddScreenState extends ConsumerState<SessionAddScreen> {
  static const _slots = [
    '08.00–10.00',
    '10.00–12.00',
    '13.00–15.00',
    '15.00–17.00',
  ];

  String? _applianceId;
  final _manualName = TextEditingController();
  final _kwhOverride = TextEditingController();
  double _hours = 2;
  String _slot = _slots[1];
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _manualName.dispose();
    _kwhOverride.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      helpText: 'Tanggal pemakaian',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save({required String name, required double kwh}) async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(appDataProvider.notifier)
          .addSession(
            applianceName: name,
            date: _date,
            slotLabel: _slot,
            kwh: kwh,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      return;
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Tercatat: ${formatKwh(kwh)} dari Solar Hub.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final appliances = ref.watch(appliancesProvider);
    final tariff = ref.watch(profileProvider)?.tariffIdrPerKwh ?? 0;
    final text = Theme.of(context).textTheme;

    final selected = appliances.where((a) => a.id == _applianceId).firstOrNull;

    final override = double.tryParse(
      _kwhOverride.text.trim().replaceAll(',', '.'),
    );
    final computed = selected == null ? null : selected.watts / 1000 * _hours;
    final kwh = override ?? computed;

    final name = selected?.name ?? _manualName.text.trim();
    final bool canSave = kwh != null && kwh > 0 && name.isNotEmpty && !_saving;

    return AppScaffold(
      title: 'Catat Pemakaian Hub',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Simpan Catatan',
        loading: _saving,
        onPressed: canSave ? () => _save(name: name, kwh: kwh) : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Alat yang dipakai', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),

          if (appliances.isEmpty) ...[
            TextField(
              controller: _manualName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Misal: Oven',
                helperText:
                    'Daftarkan alat di menu Alat Usaha agar kWh dihitung '
                    'otomatis.',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ] else
            for (final a in appliances) ...[
              SelectableTile(
                icon: applianceIcon(a.kind),
                label: a.name,
                sublabel: '${a.watts.round()} W',
                selected: _applianceId == a.id,
                onTap: () => setState(() => _applianceId = a.id),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          const SizedBox(height: AppSpacing.lg),

          Text('Tanggal', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SelectableTile(
            icon: Icons.calendar_month_outlined,
            label: formatShortDayDate(_date),
            selected: false,
            onTap: _pickDate,
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Slot waktu', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in _slots)
                ChoiceChip(
                  label: Text(s),
                  selected: _slot == s,
                  onSelected: (_) => setState(() => _slot = s),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(
            'Lama pemakaian: ${_hours.toStringAsFixed(_hours % 1 == 0 ? 0 : 1)} jam',
            style: text.titleSmall,
          ),
          Slider(
            value: _hours,
            min: 0.5,
            max: 8,
            divisions: 15,
            label: '${_hours.toStringAsFixed(_hours % 1 == 0 ? 0 : 1)} jam',
            onChanged: (v) => setState(() => _hours = v),
          ),
          const SizedBox(height: AppSpacing.md),

          if (computed != null)
            SectionCard(
              tone: CardTone.mint,
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 20,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Perkiraan ${formatKwh(computed)} '
                      '≈ ${formatRupiah((computed * tariff).round())} '
                      'yang tidak Anda beli dari PLN.',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.primaryDarker,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Punya angka meteran sendiri? (opsional)',
            style: text.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _kwhOverride,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              suffixText: 'kWh',
              hintText: 'Kosongkan untuk memakai perkiraan di atas',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
