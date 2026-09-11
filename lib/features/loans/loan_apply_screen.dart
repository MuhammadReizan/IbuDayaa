import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/logic/loan_math.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/repositories/local/local_loan_repository.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../credit_score/application/credit_score_provider.dart';

/// Ajukan Pembiayaan: the member picks amount, tenor and purpose within the
/// cooperative's policy; an admin decides.
class LoanApplyScreen extends ConsumerStatefulWidget {
  const LoanApplyScreen({super.key});

  @override
  ConsumerState<LoanApplyScreen> createState() => _LoanApplyScreenState();
}

class _LoanApplyScreenState extends ConsumerState<LoanApplyScreen> {
  static const _min = LocalLoanRepository.minimumAmountIdr;

  int? _amount;
  int? _tenor;
  LoanPurpose _purpose = LoanPurpose.rawMaterial;
  final _note = TextEditingController();
  bool _agree = false;
  bool _busy = false;
  LoanApplication? _done;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final coop = data.cooperative;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;

    final done = _done;
    if (done != null) {
      return SuccessPanel(
        title: 'Pengajuan terkirim',
        message:
            'Admin ${coop?.name ?? 'koperasi'} akan meninjau pengajuan Anda. '
            'Kabar berikutnya muncul di notifikasi dan Pesan.',
        primaryLabel: 'Lihat status pengajuan',
        onPrimary: () => context.pushReplacement(Paths.loan(done.id)),
        secondaryLabel: 'Kembali ke beranda',
        onSecondary: () => context.go(Paths.memberHome),
        child: SectionCard(
          child: Column(
            children: [
              KeyValueRow(
                label: 'Nominal',
                value: formatRupiah(done.amountIdr),
                emphasize: true,
              ),
              KeyValueRow(label: 'Tenor', value: '${done.tenorMonths} bulan'),
              KeyValueRow(
                label: 'Cicilan per bulan',
                value: formatRupiah(done.monthlyInstallmentIdr),
              ),
              const Divider(height: AppSpacing.xl),
              const TimelineItem(title: 'Pengajuan dikirim', done: true),
              const TimelineItem(
                title: 'Review admin',
                done: false,
                tone: PillTone.warning,
              ),
              const TimelineItem(
                title: 'Keputusan & pencairan',
                done: false,
                isLast: true,
              ),
            ],
          ),
        ),
      );
    }

    final score = data.scoreOf(
      me.id,
      now,
      ref.read(creditScoringEngineProvider),
    );
    final eligibility = coop == null
        ? null
        : loanEligibility(
            coop: coop,
            score: score,
            hasActiveLoan: data.activeLoanOf(me.id) != null,
          );

    if (coop == null ||
        eligibility == null ||
        !eligibility.canApply ||
        eligibility.ceilingIdr < _min) {
      return AppScaffold(
        title: 'Ajukan Pembiayaan',
        onBack: () => context.pop(),
        scrollable: false,
        body: EmptyState(
          motif: BrandArtMotif.finance,
          title: 'Belum bisa mengajukan',
          message: eligibility == null
              ? 'Data koperasi tidak ditemukan.'
              : eligibility.canApply
              ? 'Plafon Anda masih di bawah minimal ${formatRupiah(_min)}.'
              : eligibility.message,
          action: SecondaryButton(
            label: 'Lihat Skor Kredit',
            expand: false,
            onPressed: () => context.pushReplacement(Paths.score),
          ),
        ),
      );
    }

    final ceiling = eligibility.ceilingIdr;
    final amount = (_amount ?? (ceiling / 2 / 100000).round() * 100000).clamp(
      _min,
      ceiling,
    );
    final tenor = _tenor ?? coop.loanTenors.first;
    final quote = quoteLoan(
      principalIdr: amount,
      tenorMonths: tenor,
      flatMonthlyRatePct: coop.loanFlatMonthlyRatePct,
    );
    final steps = ((ceiling - _min) / 100000).round();

    return AppScaffold(
      title: 'Ajukan Pembiayaan',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Kirim pengajuan',
        loading: _busy,
        onPressed: _agree ? () => _submit(amount, tenor, quote) : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(
            tone: InfoTone.success,
            title: 'Skor Anda mendukung pengajuan ini',
            message:
                'Skor ${score!.score} (${score.band.label}) · plafon hingga '
                '${formatRupiah(ceiling)} di ${coop.name}.',
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Nominal pinjaman', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(formatRupiah(amount), style: AppTypography.numeric(32)),
          ),
          if (steps > 0)
            Slider(
              value: amount.toDouble(),
              min: _min.toDouble(),
              max: ceiling.toDouble(),
              divisions: steps,
              label: formatRupiah(amount),
              onChanged: (v) =>
                  setState(() => _amount = (v / 100000).round() * 100000),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatRupiah(_min), style: text.labelSmall),
              Text(formatRupiah(ceiling), style: text.labelSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Lama cicilan', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final t in coop.loanTenors)
                ChoiceChip(
                  label: Text('$t bulan'),
                  selected: tenor == t,
                  onSelected: (_) => setState(() => _tenor = t),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Untuk keperluan', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final p in LoanPurpose.values) ...[
            SelectableTile(
              label: p.label,
              icon: switch (p) {
                LoanPurpose.rawMaterial => Icons.inventory_2_rounded,
                LoanPurpose.equipment => Icons.precision_manufacturing_rounded,
                LoanPurpose.renovation => Icons.storefront_rounded,
                LoanPurpose.other => Icons.more_horiz_rounded,
              },
              selected: _purpose == p,
              onTap: () => setState(() => _purpose = p),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Keterangan untuk admin (boleh kosong)',
            controller: _note,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            hint: 'Contoh: Beli oven kedua untuk pesanan katering.',
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            tone: CardTone.mint,
            title: 'Rincian',
            child: Column(
              children: [
                KeyValueRow(
                  label: 'Pokok pinjaman',
                  value: formatRupiah(quote.principalIdr),
                ),
                KeyValueRow(
                  label:
                      'Jasa ${formatPercent(coop.loanFlatMonthlyRatePct, decimals: 1)}/bulan × $tenor bulan',
                  value: formatRupiah(quote.totalInterestIdr),
                ),
                KeyValueRow(
                  label: 'Total dikembalikan',
                  value: formatRupiah(quote.totalRepaymentIdr),
                ),
                const Divider(height: AppSpacing.lg),
                KeyValueRow(
                  label: 'Cicilan per bulan',
                  value: formatRupiah(quote.monthlyInstallmentIdr),
                  emphasize: true,
                  valueColor: AppColors.primaryDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Jasa dihitung flat dari pokok, sesuai tarif yang ditetapkan koperasi.',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          const LoanDecisionNotice(),
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            value: _agree,
            onChanged: (v) => setState(() => _agree = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'Saya paham ini pengajuan pinjaman ke koperasi dan wajib membayar '
              'cicilan ${formatRupiah(quote.monthlyInstallmentIdr)} setiap bulan '
              'jika disetujui.',
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(int amount, int tenor, LoanQuote quote) async {
    final ok = await confirmDialog(
      context,
      title: 'Kirim pengajuan?',
      message:
          '${formatRupiah(amount)} selama $tenor bulan, cicilan '
          '${formatRupiah(quote.monthlyInstallmentIdr)}/bulan. Admin koperasi akan '
          'meninjau.',
      confirmLabel: 'Kirim',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    LoanApplication? result;
    await runAction(
      context,
      () async => result = await ref
          .read(actionsProvider)
          .submitLoan(
            amountIdr: amount,
            purpose: _purpose,
            tenorMonths: tenor,
            note: _note.text,
          ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = result;
    });
  }
}
