import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/app_data_controller.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/money.dart';

/// Set up the user's arisan circle: what it is called, the agreed monthly
/// contribution, and who is in it.
class ArisanCreateScreen extends ConsumerStatefulWidget {
  const ArisanCreateScreen({super.key});

  @override
  ConsumerState<ArisanCreateScreen> createState() => _ArisanCreateScreenState();
}

class _ArisanCreateScreenState extends ConsumerState<ArisanCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contribution = TextEditingController();
  final _memberInput = TextEditingController();
  final List<String> _members = [];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _contribution.dispose();
    _memberInput.dispose();
    super.dispose();
  }

  void _addMember() {
    final n = _memberInput.text.trim();
    if (n.isEmpty) return;
    setState(() {
      _members.add(n);
      _memberInput.clear();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(appDataProvider.notifier)
          .createArisan(
            name: _name.text.trim(),
            contributionIdr: int.parse(
              _contribution.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
            ),
            memberNames: _members,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      return;
    }
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final me = ref.watch(profileProvider)?.name ?? 'Saya';
    final contribution = int.tryParse(
      _contribution.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final totalMembers = _members.length + 1;

    return AppScaffold(
      title: 'Buat Arisan',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Buat Grup Arisan',
        loading: _saving,
        onPressed: _save,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoBanner(
              tone: InfoTone.info,
              message:
                  'Grup ini tercatat di HP Anda sebagai buku kas bersama. '
                  'Anggota lain tidak otomatis terhubung — Andalah yang '
                  'mencatat setoran dan giliran.',
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Nama grup', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Misal: Arisan Energi Melati',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Isi nama grup' : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Iuran per anggota tiap bulan', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _contribution,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: 'Misal: 150000',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final parsed = int.tryParse(
                  (v ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
                );
                if (parsed == null || parsed <= 0) return 'Isi jumlah iuran';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Anggota', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SectionCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('$me (Anda)', style: text.titleSmall)),
                ],
              ),
            ),
            for (int i = 0; i < _members.length; i++) ...[
              const SizedBox(height: AppSpacing.sm),
              SectionCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(_members[i], style: text.titleSmall)),
                    IconButton(
                      tooltip: 'Hapus',
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () => setState(() => _members.removeAt(i)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberInput,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Nama anggota'),
                    onSubmitted: (_) => _addMember(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 52,
                  child: SecondaryButton(
                    label: 'Tambah',
                    expand: false,
                    onPressed: _addMember,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            if (contribution != null && contribution > 0)
              SectionCard(
                tone: CardTone.mint,
                child: Text(
                  'Dengan $totalMembers anggota, setiap giliran akan '
                  'mengumpulkan ${formatRupiah(contribution * totalMembers)}.',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.primaryDarker,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
