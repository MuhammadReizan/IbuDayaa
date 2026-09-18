import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
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
    final l10n = AppLocalizations.of(context);
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
      success: l10n.applianceSaveSuccess,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final a = widget.existing!;
    final ok = await confirmDialog(
      context,
      title: l10n.applianceDeleteConfirmTitle,
      message: l10n.applianceDeleteConfirmMessage,
      confirmLabel: l10n.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runAction(
      context,
      () => ref.read(actionsProvider).deleteAppliance(a.id),
      success: l10n.applianceDeletedToast,
    );
    if (done && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(appStateProvider).me;
    if (me == null) return const Scaffold();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final watts = double.tryParse(_watts.text) ?? 0;
    final monthlyKwh = watts / 1000 * _hours * _days * (30 / 7);

    return AppScaffold(
      title: widget.existing == null
          ? l10n.scaffoldApplianceAdd
          : l10n.scaffoldApplianceEdit,
      onBack: () => context.pop(),
      actions: [
        if (widget.existing != null)
          IconButton(
            tooltip: l10n.actionDelete,
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
      ],
      bottomBar: PrimaryButton(
        label: l10n.actionSave,
        loading: _busy,
        onPressed: _save,
      ),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.applianceFormCategory, style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final e in kApplianceKinds.entries)
                  ChoiceChip(
                    avatar: Icon(e.value.icon, size: 18),
                    label: Text(applianceKindLabel(e.key, l10n)),
                    selected: _kind == e.key,
                    onSelected: (_) => _pickKind(e.key),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.applianceFormName,
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v ?? '').trim().isEmpty
                  ? l10n.applianceFormNameRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.applianceFormWatt,
              controller: _watts,
              keyboardType: TextInputType.number,
              helper: l10n.applianceFormWattHelper,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              validator: (v) {
                final w = double.tryParse(v ?? '');
                if (w == null || w <= 0) return l10n.applianceFormWattRequired;
                if (w > 10000) return l10n.applianceFormWattTooLarge;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.applianceFormHoursPerDay,
                    style: text.titleSmall,
                  ),
                ),
                Text(
                  l10n.applianceHoursValue(decimalText(_hours)),
                  style: text.titleSmall,
                ),
              ],
            ),
            Slider(
              value: _hours,
              min: 0.5,
              max: 24,
              divisions: 47,
              label: l10n.applianceHoursValue(decimalText(_hours)),
              onChanged: (v) => setState(() => _hours = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.applianceFormDaysPerWeek, style: text.titleSmall),
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
                      label: l10n.applianceMonthlyLabel,
                      value: formatKwh(monthlyKwh),
                    ),
                  ),
                  Expanded(
                    child: StatTile(
                      label: l10n.applianceMonthlyCostLabel,
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
