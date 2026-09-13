import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/logic/loan_math.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../shared/inputs.dart';
import 'admin_home_screen.dart';

class CoopSettingsScreen extends ConsumerStatefulWidget {
  const CoopSettingsScreen({super.key});

  @override
  ConsumerState<CoopSettingsScreen> createState() => _CoopSettingsScreenState();
}

class _CoopSettingsScreenState extends ConsumerState<CoopSettingsScreen> {
  static const _tenorOptions = [3, 6, 9, 12, 18, 24];

  final _form = GlobalKey<FormState>();
  late final _coop = ref.read(appStateProvider).data.cooperative!;
  late final _name = TextEditingController(text: _coop.name);
  late final _city = TextEditingController(text: _coop.city);
  late final _max = TextEditingController(
    text: thousands(_coop.loanMaxAmountIdr),
  );
  late final _rate = TextEditingController(
    text: decimalText(_coop.loanFlatMonthlyRatePct),
  );
  late final _solarCost = TextEditingController(
    text: thousands(_coop.solarCostPerKwpIdr),
  );
  late double _minScore = _coop.loanMinScore.toDouble();
  late final Set<int> _tenors = {..._coop.loanTenors};
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _city, _max, _rate, _solarCost]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_tenors.isEmpty) {
      showAppSnack(context, 'Pilih minimal satu tenor.', error: true);
      return;
    }
    setState(() => _busy = true);
    final latest = ref.read(appStateProvider).data.cooperative ?? _coop;
    final ok = await runAction(
      context,
      () => ref
          .read(actionsProvider)
          .updateCooperative(
            latest.copyWith(
              name: _name.text.trim(),
              city: _city.text.trim(),
              loanMaxAmountIdr: parseDigits(_max.text),
              loanFlatMonthlyRatePct: parseDecimal(_rate.text),
              loanMinScore: _minScore.round(),
              loanTenors: (_tenors.toList()..sort()),
              solarCostPerKwpIdr: parseDigits(_solarCost.text),
            ),
          ),
      success: 'Pengaturan koperasi tersimpan.',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final coop = ref.watch(appStateProvider).data.cooperative ?? _coop;
    final members = ref
        .watch(appStateProvider)
        .data
        .members
        .where((m) => !m.isAdmin)
        .length;
    final text = Theme.of(context).textTheme;
    final max = parseDigits(_max.text) ?? 0;

    return AppScaffold(
      title: 'Pengaturan Koperasi',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Simpan',
        loading: _busy,
        onPressed: _save,
      ),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InviteCodeCard(coop: coop, memberCount: members),
            const SizedBox(height: AppSpacing.sm),
            TextLinkButton(
              label: 'Buat kode baru',
              icon: Icons.refresh_rounded,
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: 'Buat kode undangan baru?',
                  message:
                      'Kode lama ${coop.inviteCode} tidak bisa dipakai lagi. Anggota '
                      'yang sudah bergabung tidak terpengaruh.',
                  confirmLabel: 'Buat kode baru',
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                await runAction(
                  context,
                  ref.read(actionsProvider).regenerateInviteCode,
                  success: 'Kode undangan diganti.',
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Nama koperasi',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Isi nama koperasi.' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Kota',
              controller: _city,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Kebijakan pinjaman', style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            const InfoBanner(
              tone: InfoTone.warning,
              message:
                  'Pastikan kebijakan ini sesuai AD/ART dan izin usaha simpan pinjam '
                  'koperasi Anda. Perubahan hanya berlaku untuk pengajuan baru.',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Plafon maksimal',
              controller: _max,
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              inputFormatters: [
                ThousandsFormatter(),
                LengthLimitingTextInputFormatter(13),
              ],
              validator: (v) => (parseDigits(v ?? '') ?? 0) < 500000
                  ? 'Minimal Rp 500.000.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Plafon tiap anggota mengikuti skornya: '
              '${[for (final e in kCeilingShareByBand.entries.toList().reversed) '${e.key.label} ${formatRupiah((max * e.value / 100000).floor() * 100000)}'].join(' · ')}.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Jasa per bulan (flat)',
              controller: _rate,
              suffixText: '%',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [decimalInput],
              validator: (v) {
                final x = parseDecimal(v ?? '');
                if (x == null || x < 0 || x > 5) return 'Isi 0 sampai 5%.';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Skor minimum untuk mengajukan',
                    style: text.titleSmall,
                  ),
                ),
                Text('${_minScore.round()}', style: text.titleMedium),
              ],
            ),
            Slider(
              value: _minScore,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_minScore.round()}',
              onChanged: (v) => setState(() => _minScore = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Pilihan tenor', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final t in _tenorOptions)
                  FilterChip(
                    label: Text('$t bulan'),
                    selected: _tenors.contains(t),
                    onSelected: (on) =>
                        setState(() => on ? _tenors.add(t) : _tenors.remove(t)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
