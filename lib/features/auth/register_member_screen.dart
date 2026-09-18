import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/credentials.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';
import '../../core/state/actions.dart';
import 'pin_views.dart';

class RegisterMemberScreen extends ConsumerStatefulWidget {
  const RegisterMemberScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  ConsumerState<RegisterMemberScreen> createState() =>
      _RegisterMemberScreenState();
}

class _RegisterMemberScreenState extends ConsumerState<RegisterMemberScreen> {
  int _step = 0;
  bool _busy = false;
  Cooperative? _coop;
  String? _codeError;

  late final _code = TextEditingController(text: widget.initialCode ?? '');
  final _name = TextEditingController();
  final _business = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    for (final c in [_code, _name, _business, _city, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _checkCode() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _codeError = null;
    });
    final coop = await ref.read(actionsProvider).findCooperative(_code.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _coop = coop;
      _codeError = coop == null ? l10n.registerMemberCodeError : null;
      if (coop != null) {
        if (_city.text.isEmpty) _city.text = coop.city;
        _step = 1;
      }
    });
  }

  Future<void> _submit(String pin) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    await runAction(
      context,
      () => ref
          .read(actionsProvider)
          .registerMember(
            phone: _phone.text,
            pin: pin,
            fullName: _name.text,
            businessName: _business.text,
            city: _city.text,
            inviteCode: _code.text,
          ),
      success: l10n.registerMemberSuccessNamed(
        _coop?.name ?? l10n.registerMemberGenericCoop,
      ),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final steps = [
      l10n.registerStepCode,
      l10n.registerStepPerson,
      l10n.labelPin,
    ];

    if (_step == 2) {
      return AppScaffold(
        title: l10n.registerMemberTitle,
        onBack: _back,
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
      title: l10n.registerMemberTitle,
      onBack: _back,
      bottomBar: PrimaryButton(
        label: l10n.actionContinue,
        loading: _busy,
        onPressed: _step == 0
            ? (_code.text.trim().length == 6 ? _checkCode : null)
            : () {
                if (_form.currentState!.validate()) {
                  FocusScope.of(context).unfocus();
                  setState(() => _step = 2);
                }
              },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepDots(labels: steps, current: _step),
          const SizedBox(height: AppSpacing.xl),
          if (_step == 0) ...[
            Text(l10n.registerMemberStep0Title, style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.registerMemberStep0Subtitle, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _code,
              autofocus: widget.initialCode == null,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              onChanged: (_) => setState(() => _codeError = null),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                _UpperCase(),
              ],
              style: text.headlineMedium?.copyWith(letterSpacing: 8),
              decoration: InputDecoration(
                hintText: l10n.registerMemberCodeHint,
                counterText: '',
                errorText: _codeError,
              ),
            ),
          ] else ...[
            if (_coop != null)
              SectionCard(
                tone: CardTone.mint,
                child: Row(
                  children: [
                    const FeatureBadge(
                      icon: Icons.verified_rounded,
                      tone: BadgeTone.forest,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.registerMemberJoiningTo,
                            style: text.bodySmall,
                          ),
                          Text(_coop!.name, style: text.titleMedium),
                          Text(_coop!.city, style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Form(
              key: _form,
              child: Column(
                children: [
                  AppTextField(
                    label: l10n.registerMemberFieldName,
                    controller: _name,
                    hint: l10n.registerMemberFieldNameHint,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: _required(l10n, l10n.registerMemberFieldName),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.registerMemberFieldBusiness,
                    controller: _business,
                    hint: l10n.registerMemberFieldBusinessHint,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: _required(
                      l10n,
                      l10n.registerMemberFieldBusiness,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.registerMemberFieldCity,
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: _required(l10n, l10n.registerMemberFieldCity),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.registerMemberFieldPhone,
                    controller: _phone,
                    hint: l10n.loginPhoneHint,
                    keyboardType: TextInputType.phone,
                    helper: l10n.registerMemberFieldPhoneHelper,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
                      LengthLimitingTextInputFormatter(17),
                    ],
                    validator: (v) => normalizeIndonesianPhone(v ?? '') == null
                        ? l10n.registerMemberFieldPhoneError
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

FormFieldValidator<String> _required(AppLocalizations l10n, String label) =>
    (v) => (v ?? '').trim().isEmpty ? l10n.fieldRequired(label) : null;

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) => next.copyWith(text: next.text.toUpperCase());
}
