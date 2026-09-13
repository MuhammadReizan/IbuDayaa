import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../shared/inputs.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // PLN household tariffs for non-subsidised connections (2024). Shown as
  // shortcuts only; the bill itself is the source of truth.
  static const _tariffs = [
    (label: '900 VA non-subsidi', value: 1352.0),
    (label: '1.300–2.200 VA', value: 1444.70),
    (label: '3.500 VA ke atas', value: 1699.53),
  ];

  final _form = GlobalKey<FormState>();
  late final me = ref.read(appStateProvider).me!;
  late final _name = TextEditingController(text: me.fullName);
  late final _business = TextEditingController(text: me.businessName);
  late final _city = TextEditingController(text: me.city);
  late final _tariff = TextEditingController(
    text: me.tariffIdrPerKwh.toStringAsFixed(2).replaceAll('.', ','),
  );
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _business, _city, _tariff]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref
          .read(actionsProvider)
          .updateProfile(
            me.copyWith(
              fullName: _name.text,
              businessName: _business.text,
              city: _city.text,
              tariffIdrPerKwh: parseDecimal(_tariff.text),
            ),
          ),
      success: 'Profil tersimpan.',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.scaffoldProfileEdit,
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: l10n.actionSave,
        loading: _busy,
        onPressed: _save,
      ),
      body: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: l10n.editProfileName,
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.labelRequired : null,
            ),
            if (!me.isAdmin) ...[
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l10n.editProfileBusiness,
                controller: _business,
                textCapitalization: TextCapitalization.words,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.editProfileCity,
              controller: _city,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.labelPhone,
              controller: TextEditingController(text: me.displayPhone),
              enabled: false,
            ),
            if (!me.isAdmin) ...[
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: l10n.editProfileTariff,
                controller: _tariff,
                prefixText: 'Rp ',
                suffixText: '/kWh',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [decimalInput],
                validator: (v) {
                  final x = parseDecimal(v ?? '');
                  if (x == null || x < 100 || x > 5000) {
                    return l10n.labelRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final t in _tariffs)
                    ActionChip(
                      label: Text('${t.label} · ${formatRupiah(t.value)}'),
                      onPressed: () => setState(
                        () => _tariff.text = t.value
                            .toStringAsFixed(2)
                            .replaceAll('.', ','),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
