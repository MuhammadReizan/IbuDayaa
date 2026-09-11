import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/credentials.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
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
      success: 'Koperasi berhasil dibuat.',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const steps = ['Data diri', 'Koperasi', 'PIN'];
    void back() => _step == 0 ? context.pop() : setState(() => _step--);

    if (_step == 2) {
      return AppScaffold(
        title: 'Daftar Admin',
        onBack: back,
        scrollable: false,
        body: Column(
          children: [
            const StepDots(labels: steps, current: 2),
            Expanded(
              child: PinCreateView(onCreated: _submit, busy: _busy),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      title: 'Daftar Admin',
      onBack: back,
      bottomBar: PrimaryButton(
        label: 'Lanjut',
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
                  Text('Data pengurus', style: text.headlineSmall),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: 'Nama lengkap',
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    validator: _required('Nama'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Nomor HP',
                    controller: _phone,
                    hint: '0812 3456 7890',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ \-]')),
                      LengthLimitingTextInputFormatter(17),
                    ],
                    validator: (v) => normalizeIndonesianPhone(v ?? '') == null
                        ? 'Nomor HP tidak valid.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Kota',
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    validator: _required('Kota'),
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
                  Text('Koperasi Anda', style: text.headlineSmall),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: 'Nama koperasi',
                    controller: _coopName,
                    hint: 'Contoh: Koperasi Energi Melati',
                    textCapitalization: TextCapitalization.words,
                    validator: _required('Nama koperasi'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const InfoBanner(
                    tone: InfoTone.info,
                    title: 'Setelah ini',
                    message:
                        'Anda mendapat kode koperasi untuk dibagikan ke anggota. '
                        'Atur kapasitas Solar Hub dan kebijakan pinjaman di menu '
                        'Lainnya → Pengaturan koperasi.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const InfoBanner(
                    tone: InfoTone.warning,
                    message:
                        'Pinjaman ke anggota harus dijalankan oleh koperasi '
                        'yang berbadan hukum dan berizin simpan pinjam. '
                        'Aplikasi hanya membantu mencatat dan meninjau.',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

FormFieldValidator<String> _required(String label) =>
    (v) => (v ?? '').trim().isEmpty ? '$label wajib diisi.' : null;
