import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/credentials.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/errors.dart';
import '../../core/l10n/l10n.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import 'pin_views.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _confirmedPhone;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = _confirmedPhone;
    if (phone != null) {
      final l10n = AppLocalizations.of(context);
      return AppScaffold(
        title: l10n.loginPinTitle,
        onBack: () => setState(() => _confirmedPhone = null),
        scrollable: false,
        body: PinEntryView(
          title: l10n.loginPinSubtitle,
          subtitle: 'Masukkan PIN untuk $phone',
          onSubmit: (pin) async {
            try {
              await ref.read(actionsProvider).login(phone, pin);
              return null;
            } on AppException catch (e) {
              return e.message;
            }
          },
          footer: TextLinkButton(
            label: l10n.loginForgotPin,
            onPressed: _forgotPin,
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AppScaffold(
      title: l10n.loginTitle,
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(label: l10n.actionContinue, onPressed: _next),
      body: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.loginPhonePrompt, style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.loginPhoneHelper, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: l10n.loginPhoneLabel,
              controller: _phone,
              hint: l10n.loginPhoneHint,
              prefixIcon: Icons.phone_iphone_rounded,
              keyboardType: TextInputType.phone,
              autofocus: true,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
                LengthLimitingTextInputFormatter(17),
              ],
              validator: (v) => normalizeIndonesianPhone(v ?? '') == null
                  ? l10n.loginPhoneError
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.loginNoAccount, style: text.bodyMedium),
                TextLinkButton(
                  label: l10n.actionRegister,
                  onPressed: () => context.pushReplacement(Paths.register),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _confirmedPhone = _phone.text.trim());
  }

  Future<void> _forgotPin() async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.loginForgotPinTitle),
        content: Text(l10n.loginForgotPinBody),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await confirmDialog(
                context,
                title: l10n.loginClearDataConfirmTitle,
                message: l10n.loginClearDataConfirmBody,
                confirmLabel: l10n.loginClearDataConfirmLabel,
                destructive: true,
              );
              if (!ok || !mounted) return;
              final done = await runAction(
                context,
                ref.read(actionsProvider).resetDevice,
                success: l10n.loginClearDataSuccess,
              );
              if (done && mounted) context.go(Paths.welcome);
            },
            child: Text(
              l10n.loginClearData,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(kMinTapTarget, kMinTapTarget),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.loginUnderstood),
          ),
        ],
      ),
    );
  }
}
