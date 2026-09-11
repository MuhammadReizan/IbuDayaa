import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/brand/brand.dart';
import '../../../core/data/app_data_controller.dart';
import '../../../core/data/models.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';

/// First run. Collects the little we need to make every later number the
/// user's own: who they are, what they sell, and what they pay per kWh.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _business = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _tariff = TextEditingController(text: '1444.70');

  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _business.dispose();
    _city.dispose();
    _phone.dispose();
    _tariff.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final tariff =
        double.tryParse(_tariff.text.trim().replaceAll(',', '.')) ?? 1444.70;

    try {
      await ref
          .read(appDataProvider.notifier)
          .completeOnboarding(
            UserProfile(
              name: _name.text.trim(),
              businessName: _business.text.trim(),
              city: _city.text.trim(),
              phone: _phone.text.trim(),
              joinedAt: DateTime.now(),
              tariffIdrPerKwh: tariff,
            ),
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
      return;
    }

    if (!mounted) return;
    context.go(AppRoute.homePath);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      bottomBar: PrimaryButton(
        label: 'Mulai Pakai IbuDaya',
        loading: _saving,
        onPressed: _submit,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(child: BrandArt(motif: BrandArtMotif.community, size: 132)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Selamat datang di IbuDaya',
              style: text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Catat pemakaian listrik dan arisan usaha Anda. Semua data '
              'tersimpan di HP ini saja — tidak dikirim ke mana pun.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Nama Anda', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Misal: Ibu Sari'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Nama usaha', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _business,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Misal: Katering Sari Rasa',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama usaha wajib diisi'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Kota', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Misal: Palembang'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Kota wajib diisi' : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Nomor HP (opsional)', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '08xx-xxxx-xxxx'),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Tarif listrik per kWh', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _tariff,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                helperText: 'Lihat di struk PLN Anda. Bisa diubah nanti.',
              ),
              validator: (v) {
                final parsed = double.tryParse(
                  (v ?? '').trim().replaceAll(',', '.'),
                );
                if (parsed == null || parsed <= 0) return 'Tarif tidak valid';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            const InfoBanner(
              tone: InfoTone.info,
              title: 'Data Anda milik Anda',
              message:
                  'IbuDaya bekerja penuh tanpa internet. Tidak ada akun, tidak '
                  'ada server, dan tidak ada data yang dibagikan tanpa Anda '
                  'ekspor sendiri.',
            ),
          ],
        ),
      ),
    );
  }
}
