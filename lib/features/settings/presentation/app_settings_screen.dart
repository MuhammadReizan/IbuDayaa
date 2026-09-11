import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/data/app_data_controller.dart';
import '../../../core/data/sample_data.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';

/// Profile editing plus the things people need control over: their tariff,
/// sample data for trying the app out, and a way to erase everything.
class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _business;
  late final TextEditingController _city;
  late final TextEditingController _tariff;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _name = TextEditingController(text: p?.name ?? '');
    _business = TextEditingController(text: p?.businessName ?? '');
    _city = TextEditingController(text: p?.city ?? '');
    _tariff = TextEditingController(
      text: (p?.tariffIdrPerKwh ?? 0).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _business.dispose();
    _city.dispose();
    _tariff.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final p = ref.read(profileProvider);
    if (p == null) return;
    final tariff = double.tryParse(_tariff.text.trim().replaceAll(',', '.'));
    final messenger = ScaffoldMessenger.of(context);

    await ref
        .read(appDataProvider.notifier)
        .updateProfile(
          p.copyWith(
            name: _name.text.trim().isEmpty ? p.name : _name.text.trim(),
            businessName: _business.text.trim(),
            city: _city.text.trim(),
            tariffIdrPerKwh: (tariff != null && tariff > 0) ? tariff : null,
          ),
        );
    if (!mounted) return;
    setState(() => _dirty = false);
    messenger.showSnackBar(const SnackBar(content: Text('Profil diperbarui.')));
  }

  Future<void> _loadSample() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _confirm(
      title: 'Muat data contoh?',
      body:
          'Semua catatan Anda saat ini akan diganti dengan data contoh untuk '
          'peragaan. Tindakan ini tidak bisa dibatalkan.',
      confirmLabel: 'Muat',
    );
    if (ok != true) return;

    await ref
        .read(appDataProvider.notifier)
        .replaceAll(buildSampleData(ref.read(profileProvider)));
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Data contoh dimuat.')),
    );
  }

  Future<void> _clearAll() async {
    final ok = await _confirm(
      title: 'Hapus semua data?',
      body:
          'Seluruh catatan tagihan, alat, arisan, dan profil Anda akan '
          'dihapus dari HP ini secara permanen.',
      confirmLabel: 'Hapus Semua',
      destructive: true,
    );
    if (ok != true) return;

    await ref.read(appDataProvider.notifier).clearAll();
    if (!mounted) return;
    context.go(AppRoute.onboardingPath);
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final data = ref.watch(dataProvider);

    return AppScaffold(
      title: 'Pengaturan & Data',
      onBack: () => context.pop(),
      bottomBar: _dirty
          ? PrimaryButton(label: 'Simpan Perubahan', onPressed: _saveProfile)
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Profil', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nama'),
            onChanged: (_) => setState(() => _dirty = true),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _business,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nama usaha'),
            onChanged: (_) => setState(() => _dirty = true),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Kota'),
            onChanged: (_) => setState(() => _dirty = true),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _tariff,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Tarif listrik per kWh',
              prefixText: 'Rp ',
              helperText:
                  'Mengubah ini akan mengubah semua perhitungan biaya Anda.',
            ),
            onChanged: (_) => setState(() => _dirty = true),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Data Anda', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Stat(label: 'Tagihan tercatat', value: '${data.bills.length}'),
                const Divider(height: AppSpacing.lg),
                _Stat(label: 'Alat usaha', value: '${data.appliances.length}'),
                const Divider(height: AppSpacing.lg),
                _Stat(
                  label: 'Pemakaian Solar Hub',
                  value: '${data.sessions.length}',
                ),
                const Divider(height: AppSpacing.lg),
                _Stat(
                  label: 'Transaksi arisan',
                  value: '${data.ledger.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const InfoBanner(
            tone: InfoTone.info,
            title: 'Semua tersimpan di HP ini',
            message:
                'IbuDaya tidak mengirim data Anda ke server mana pun. Kalau HP '
                'hilang atau aplikasi dihapus, catatan ikut hilang — simpan '
                'juga di buku sebagai cadangan.',
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Lainnya', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryDark,
                  ),
                  title: Text('Tentang IbuDaya', style: text.titleSmall),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () => context.push(AppRoute.aboutPath),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.science_outlined,
                    color: AppColors.primaryDark,
                  ),
                  title: Text('Muat data contoh', style: text.titleSmall),
                  subtitle: Text(
                    'Isi aplikasi dengan contoh untuk peragaan',
                    style: text.bodySmall,
                  ),
                  onTap: _loadSample,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: AppColors.danger,
                  ),
                  title: Text(
                    'Hapus semua data',
                    style: text.titleSmall?.copyWith(color: AppColors.danger),
                  ),
                  onTap: _clearAll,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(child: Text(AppConfig.versionLabel, style: text.labelSmall)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: text.bodyMedium)),
        Text(value, style: text.titleSmall),
      ],
    );
  }
}
