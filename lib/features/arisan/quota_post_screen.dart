import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/quota_insights.dart';
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
  final _note = TextEditingController();
  bool _busy = false;
  QuotaOffer? _done;

  /// Share only: false = to anyone (market), true = to one chosen member.
  bool _direct = false;
  String? _toMember;

  @override
  void dispose() {
    _custom.dispose();
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
        message: done.counterpartyId != null
            ? l10n.quotaGiftSentMessage(s.data.nameOf(done.counterpartyId))
            : share
            ? l10n.arisanQuotaShare
            : l10n.arisanQuotaNeed,
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

    final members = [
      for (final m in s.data.memberProfiles)
        if (m.id != me.id) m,
    ];
    final suggestions = _direct
        ? const <QuotaMatch>[]
        : matchQuotaOffers(
            offers: s.data.activeOffers,
            myId: me.id,
            wantKind: widget.kind,
            wantedKwh: kwh,
            availableKwh: quota.availableKwh,
          ).take(3).toList();

    return AppScaffold(
      title: share ? l10n.arisanQuotaShare : l10n.arisanQuotaNeed,
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: l10n.actionSubmit,
        loading: _busy,
        onPressed: kwh <= 0 || tooMuch || (_direct && _toMember == null)
            ? null
            : () => _submit(kwh),
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
          if (share) ...[
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text(l10n.quotaShareToAny),
                  selected: !_direct,
                  onSelected: (_) => setState(() => _direct = false),
                ),
                ChoiceChip(
                  label: Text(l10n.quotaShareToMember),
                  selected: _direct,
                  onSelected: (_) => setState(() => _direct = true),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _direct ? l10n.quotaShareToMemberHint : l10n.quotaShareToAnyHint,
              style: text.bodySmall,
            ),
            if (_direct) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l10n.quotaPickMember, style: text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              for (final m in members) ...[
                SelectableTile(
                  icon: Icons.person_rounded,
                  label: m.fullName,
                  sublabel: m.businessName,
                  selected: _toMember == m.id,
                  onTap: () => setState(() => _toMember = m.id),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.quotaMatchTitle, style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final m in suggestions) ...[
              SectionCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.data.nameOf(m.offer.ownerId),
                            style: text.titleSmall,
                          ),
                          Text(
                            _reason(l10n, m, kwh),
                            style: text.bodySmall?.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 110,
                      child: PrimaryButton(
                        label: share
                            ? l10n.arisanQuotaShare
                            : l10n.arisanQuotaNeed,
                        onPressed: () => _trade(m.offer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(l10n.quotaMatchRule, style: text.bodySmall),
          ],
          const SizedBox(height: AppSpacing.xl),
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

  String _reason(AppLocalizations l10n, QuotaMatch m, double wanted) {
    if (widget.kind == QuotaKind.share) {
      return l10n.quotaMatchNeedFits(formatKwh(m.offer.kwh));
    }
    return m.covers
        ? l10n.quotaMatchShareCovers(formatKwh(m.offer.kwh))
        : l10n.quotaMatchShareShort(
            formatKwh(m.offer.kwh),
            formatKwh(wanted - m.offer.kwh),
          );
  }

  /// One tap trades with a suggested offer: it completes at once.
  Future<void> _trade(QuotaOffer offer) async {
    final l10n = AppLocalizations.of(context);
    final data = ref.read(appStateProvider).data;
    final ok = await confirmDialog(
      context,
      title: widget.kind == QuotaKind.share
          ? l10n.arisanQuotaShare
          : l10n.arisanQuotaNeed,
      message: l10n.quotaTradeConfirm(
        formatKwh(offer.kwh),
        data.nameOf(offer.ownerId),
      ),
      confirmLabel: widget.kind == QuotaKind.share
          ? l10n.arisanQuotaShare
          : l10n.arisanQuotaNeed,
    );
    if (!ok || !mounted) return;
    final done = await runAction(
      context,
      () => ref.read(actionsProvider).respondToQuota(offer.id),
      success: l10n.quotaTradedToast,
    );
    if (done && mounted) context.pop();
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
            note: _note.text,
            toMemberId: _direct ? _toMember : null,
          ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = result;
    });
  }
}
