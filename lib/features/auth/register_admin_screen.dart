import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/credentials.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/state/actions.dart';
import 'pin_views.dart';

class RegisterAdminScreen extends ConsumerStatefulWidget {
  const RegisterAdminScreen({super.key});

  @override
  ConsumerState<RegisterAdminScreen> createState() =>
      _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends ConsumerState<RegisterAdminScreen> {
  int _step = 0;
  bool _busy = false;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _coopName = TextEditingController();
  final _personForm = GlobalKey<FormState>();
  final _coopForm = GlobalKey<FormState>();

  @override
  void dispose() {
    for (final c in [_name, _phone, _city, _coopName]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(String pin) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    await runAction(
      context,
      () => ref
          .read(actionsProvider)
          .registerAdmin(
            phone: _phone.text,
            pin: pin,
            fullName: _name.text,
            city: _city.text,
            cooperativeName: _coopName.text,
          ),
      success: l10n.registerAdminPinCreated,
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final steps = [
      l10n.registerStepPerson,
      l10n.registerStepCoop,
      l10n.labelPin,
    ];
    void back() => _step == 0 ? context.pop() : setState(() => _step--);

    if (_step == 2) {
      return AppScaffold(
        title: l10n.registerAdminTitle,
        onBack: back,
        scrollable: false,
        body: Column(
          children: [
            StepDots(labels: steps, current: 2),
            Expanded(
              child: PinCreateView(onCreated: _submit, busy: _busy),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      title: l10n.registerAdminTitle,
      onBack: back,
      bottomBar: PrimaryButton(
        label: l10n.actionContinue,
        onPressed: () {
          final form = _step == 0 ? _personForm : _coopForm;
          if (!form.currentState!.validate()) return;
          FocusScope.of(context).unfocus();
          setState(() => _step++);
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepDots(labels: steps, current: _step),
          const SizedBox(height: AppSpacing.xl),
          if (_step == 0)
            Form(
              key: _personForm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.registerAdminSectionPerson,
                    style: text.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: l10n.registerMemberFieldName,
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    validator: _required(l10n, l10n.registerMemberFieldName),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.labelPhone,
                    controller: _phone,
                    hint: l10n.loginPhoneHint,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
                      LengthLimitingTextInputFormatter(17),
                    ],
                    validator: (v) => normalizeIndonesianPhone(v ?? '') == null
                        ? l10n.registerMemberFieldPhoneError
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.labelCity,
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    validator: _required(l10n, l10n.labelCity),
                  ),
                ],
              ),
            )
          else
            Form(
              key: _coopForm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.registerAdminCoopHeading,
                    style: text.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: l10n.registerAdminCoopName,
                    controller: _coopName,
                    hint: l10n.registerAdminCoopNameHint,
                    textCapitalization: TextCapitalization.words,
                    validator: _required(l10n, l10n.registerAdminCoopName),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  InfoBanner(
                    tone: InfoTone.info,
                    title: l10n.registerAdminAfterTitle,
                    message: l10n.registerAdminAfterBody,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InfoBanner(
                    tone: InfoTone.warning,
                    message: l10n.registerAdminLegalWarning,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

FormFieldValidator<String> _required(AppLocalizations l10n, String label) =>
    (v) => (v ?? '').trim().isEmpty ? l10n.fieldRequired(label) : null;
