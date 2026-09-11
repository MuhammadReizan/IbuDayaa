import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/credentials.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/errors.dart';
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
      return AppScaffold(
        title: 'Masukkan PIN',
        onBack: () => setState(() => _confirmedPhone = null),
        scrollable: false,
        body: PinEntryView(
          title: 'Halo, selamat datang kembali',
          subtitle: 'Masukkan PIN untuk $phone',
          onSubmit: (pin) async {
            try {
              await ref.read(actionsProvider).login(phone, pin);
              return null;
            } on AppException catch (e) {
              return e.message;
            }
          },
          footer: TextLinkButton(label: 'Lupa PIN?', onPressed: _forgotPin),
        ),
      );
    }

    final text = Theme.of(context).textTheme;
    return AppScaffold(
      title: 'Masuk',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(label: 'Lanjut', onPressed: _next),
      body: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nomor HP Anda', style: text.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pakai nomor yang Anda daftarkan di IbuDaya.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Nomor HP',
              controller: _phone,
              hint: '0812 3456 7890',
              prefixIcon: Icons.phone_iphone_rounded,
              keyboardType: TextInputType.phone,
              autofocus: true,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
                LengthLimitingTextInputFormatter(17),
              ],
              validator: (v) => normalizeIndonesianPhone(v ?? '') == null
                  ? 'Nomor HP tidak valid. Contoh: 0812 3456 7890'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Belum punya akun?', style: text.bodyMedium),
                TextLinkButton(
                  label: 'Daftar',
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
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lupa PIN'),
        content: const Text(
          'Saat ini akun tersimpan hanya di HP ini, jadi PIN tidak bisa '
          'dikirim ulang. Setelah terhubung ke server koperasi, PIN bisa '
          'diatur ulang lewat SMS.\n\nJika benar-benar lupa, Anda bisa '
          'menghapus semua data di HP ini lalu mendaftar lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await confirmDialog(
                context,
                title: 'Hapus semua data?',
                message:
                    'Semua akun, catatan listrik, arisan, dan pinjaman di HP '
                    'ini akan hilang dan tidak bisa dikembalikan.',
                confirmLabel: 'Hapus semua',
                destructive: true,
              );
              if (!ok || !mounted) return;
              final done = await runAction(
                context,
                ref.read(actionsProvider).resetDevice,
                success: 'Data di HP ini sudah dihapus.',
              );
              if (done && mounted) context.go(Paths.welcome);
            },
            child: const Text(
              'Hapus data',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(kMinTapTarget, kMinTapTarget),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}
