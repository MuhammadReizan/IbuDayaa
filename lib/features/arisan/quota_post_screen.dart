import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../shared/inputs.dart';

/// "Bagikan Kuota" / "Butuh Kuota", ending on "Penawaran Berhasil".
class QuotaPostScreen extends ConsumerStatefulWidget {
  const QuotaPostScreen({super.key, required this.kind});

  final QuotaKind kind;

  @override
  ConsumerState<QuotaPostScreen> createState() => _QuotaPostScreenState();
}

class _QuotaPostScreenState extends ConsumerState<QuotaPostScreen> {
  double _kwh = 2;
  final _custom = TextEditingController();
  final _when = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  QuotaOffer? _done;

  @override
  void dispose() {
    _custom.dispose();
    _when.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final share = widget.kind == QuotaKind.share;
    final now = ref.read(clockProvider)();
    final quota = s.data.quotaOf(me.id, now);
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final kwh = _custom.text.isEmpty ? _kwh : (parseDecimal(_custom.text) ?? 0);
    final tooMuch = share && kwh > quota.availableKwh + 1e-9;

    final done = _done;
    if (done != null) {
      return SuccessPanel(
        title: l10n.labelSuccess,
        message: share ? l10n.arisanQuotaShare : l10n.arisanQuotaNeed,
        primaryLabel: l10n.arisanEnergyTrading,
        onPrimary: () => context.pop(),
        child: SectionCard(
          tone: CardTone.mint,
          child: Column(
            children: [
              KeyValueRow(
                label: l10n.labelStatus,
                value: share ? l10n.arisanQuotaShare : l10n.arisanQuotaNeed,
              ),
              KeyValueRow(
                label: l10n.labelAmount,
                value: formatKwh(done.kwh),
                emphasize: true,
              ),
              if (done.slotNote.isNotEmpty)
                KeyValueRow(label: l10n.labelDate, value: done.slotNote),
              if (share)
                KeyValueRow(
                  label: l10n.solarQuotaThisMonth,
                  value: formatKwh(quota.availableKwh - done.kwh),
                ),
            ],
          ),
        ),
      );
    }

    final slots = s.data.orderedSlots;

    return AppScaffold(
      title: share ? l10n.arisanQuotaShare : l10n.arisanQuotaNeed,
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: l10n.actionSubmit,
        loading: _busy,
        onPressed: kwh <= 0 || tooMuch ? null : () => _submit(kwh),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            tone: CardTone.mint,
            child: Row(
              children: [
                const FeatureBadge(
                  icon: Icons.bolt_rounded,
                  tone: BadgeTone.forest,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(l10n.solarQuotaThisMonth, style: text.bodyMedium),
                ),
                Text(
                  formatKwh(quota.availableKwh),
                  style: AppTypography.numeric(20),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            share ? l10n.arisanQuotaShare : l10n.arisanQuotaNeed,
            style: text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final v in const [1.0, 2.0, 3.0, 5.0])
                ChoiceChip(
                  label: Text(formatKwh(v)),
                  selected: _custom.text.isEmpty && _kwh == v,
                  onSelected: (_) => setState(() {
                    _kwh = v;
                    _custom.clear();
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: l10n.labelAmount,
            controller: _custom,
            suffixText: 'kWh',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [decimalInput],
            onChanged: (_) => setState(() {}),
          ),
          if (tooMuch) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              formatKwh(quota.availableKwh),
              style: text.bodySmall?.copyWith(color: AppColors.dangerText),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: l10n.labelDate,
            controller: _when,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final label in [for (final sl in slots.take(3)) sl.label])
                ActionChip(
                  label: Text(label),
                  onPressed: () => setState(() {
                    _when.text =
                        _when.text.isEmpty ||
                            label.contains('.') == _when.text.contains('.')
                        ? label
                        : '${_when.text}, $label';
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: '${l10n.labelNote} (${l10n.labelOptional})',
            controller: _note,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Future<void> _submit(double kwh) async {
    setState(() => _busy = true);
    QuotaOffer? result;
    await runAction(
      context,
      () async => result = await ref
          .read(actionsProvider)
          .postQuota(
            kind: widget.kind,
            kwh: kwh,
            slotNote: _when.text,
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
