import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/row.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/arisan_draw.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../shared/inputs.dart';

class ArisanAdminScreen extends ConsumerWidget {
  const ArisanAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStateProvider).data;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.scaffoldAdminArisan,
      onBack: () => context.pop(),
      scrollable: data.groups.isNotEmpty,
      bottomBar: PrimaryButton(
        label: l10n.arisanAdminCreateGroupButton,
        icon: Icons.add_rounded,
        onPressed: () => context.push(Paths.adminArisanNew),
      ),
      body: data.groups.isEmpty
          ? EmptyState(
              motif: BrandArtMotif.arisan,
              title: l10n.arisanAdminEmptyTitle,
              message: l10n.arisanAdminEmptyMessage,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final g in data.groups) ...[
                  Builder(
                    builder: (context) {
                      final members = data.membersOfGroup(g.id);
                      final started = !monthOf(now).isBefore(g.startMonth);
                      final recipient = data.recipientFor(g, now);
                      final paid = members
                          .where(
                            (m) =>
                                data
                                    .contributionFor(g.id, m.userId, now)
                                    ?.status ==
                                PaymentStatus.confirmed,
                          )
                          .length;
                      final payout = data
                          .paymentsOfGroup(g.id)
                          .where(
                            (p) =>
                                p.type == PaymentType.payout &&
                                sameMonth(p.periodMonth, now),
                          )
                          .firstOrNull;
                      return SectionCard(
                        title: g.name,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            KeyValueRow(
                              label: l10n.arisanAdminDuesPerMonth,
                              value: formatRupiah(g.contributionIdr),
                            ),
                            KeyValueRow(
                              label: l10n.adminMembers,
                              value: l10n.arisanAdminMemberCount(
                                members.length,
                              ),
                            ),
                            KeyValueRow(
                              label: l10n.arisanAdminStartMonth,
                              value: monthYearLabel(g.startMonth),
                            ),
                            if (started) ...[
                              KeyValueRow(
                                label: l10n.arisanAdminPaidThisMonth,
                                value: '$paid / ${members.length}',
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              AppProgressBar(
                                value: members.isEmpty
                                    ? 0
                                    : paid / members.length,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (payout != null)
                                InfoBanner(
                                  tone: InfoTone.success,
                                  message: l10n.arisanAdminDisbursedTo(
                                    data.nameOf(payout.userId),
                                    formatRupiah(payout.amountIdr),
                                  ),
                                )
                              else if (recipient != null)
                                PrimaryButton(
                                  label: l10n.arisanAdminRecordPayoutTo(
                                    data.nameOf(recipient.userId),
                                  ),
                                  onPressed: () async {
                                    final ok = await confirmDialog(
                                      context,
                                      title: l10n
                                          .arisanAdminRecordPayoutConfirmTitle,
                                      message:
                                          l10n.arisanAdminRecordPayoutConfirmMessage(
                                            formatRupiah(
                                              g.contributionIdr *
                                                  members.length,
                                            ),
                                            data.nameOf(recipient.userId),
                                            monthYearLabel(now),
                                          ) +
                                          (paid < members.length
                                              ? l10n.arisanAdminRecordPayoutWarning(
                                                  paid,
                                                  members.length,
                                                )
                                              : ''),
                                      confirmLabel:
                                          l10n.arisanAdminRecordPayoutAction,
                                    );
                                    if (!ok || !context.mounted) return;
                                    await runAction(
                                      context,
                                      () => ref
                                          .read(actionsProvider)
                                          .recordPayout(g.id, recipient.userId),
                                      success:
                                          l10n.arisanAdminPayoutRecordedToast,
                                    );
                                  },
                                ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.arisanAdminTurnOrderSection,
                              style: text.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            for (final m in members)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${m.turnOrder}.',
                                        style: text.bodyMedium,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        data.nameOf(m.userId),
                                        style: text.bodyMedium,
                                      ),
                                    ),
                                    Text(
                                      shortMonthYear(
                                        arisanTurnMonth(
                                          startMonth: g.startMonth,
                                          turnOrder: m.turnOrder,
                                          memberCount: members.length,
                                          now: now,
                                        ),
                                        l10n: l10n,
                                      ),
                                      style: text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
    );
  }
}

class ArisanCreateScreen extends ConsumerStatefulWidget {
  const ArisanCreateScreen({super.key});

  @override
  ConsumerState<ArisanCreateScreen> createState() => _ArisanCreateScreenState();
}

class _ArisanCreateScreenState extends ConsumerState<ArisanCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Arisan Digital');
  final _amount = TextEditingController(text: '100.000');
  late DateTime _start = monthOf(ref.read(clockProvider)());
  final List<String> _order = [];
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStateProvider).data;
    final now = ref.read(clockProvider)();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final members = data.memberProfiles;

    return AppScaffold(
      title: l10n.arisanAdminCreateTitle,
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: l10n.arisanAdminCreateButton(_order.length),
        loading: _busy,
        onPressed: _order.length < 2 ? null : _submit,
      ),
      body: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: l10n.adminArisanGroupName,
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v ?? '').trim().isEmpty
                  ? l10n.arisanAdminGroupNameRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.arisanAdminDuesPerMonth,
              controller: _amount,
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              inputFormatters: [
                ThousandsFormatter(),
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (v) => (parseDigits(v ?? '') ?? 0) < 1000
                  ? l10n.arisanAdminMinAmount
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.arisanAdminStartMonthLabel, style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<DateTime>(
              value: _start,
              items: [
                for (int i = 0; i < 3; i++)
                  DropdownMenuItem(
                    value: DateTime(now.year, now.month + i),
                    child: Text(
                      monthYearLabel(DateTime(now.year, now.month + i)),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _start = v ?? _start),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.arisanAdminPickMembersTitle, style: text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.arisanAdminPickMembersHint, style: text.bodySmall),
            if (_order.length >= 2) ...[
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: l10n.arisanDrawButton,
                icon: Icons.casino_rounded,
                expand: false,
                onPressed: () async {
                  final drawn = await showDialog<List<String>>(
                    context: context,
                    builder: (_) => _ArisanDrawDialog(
                      memberIds: _order,
                      nameOf: data.nameOf,
                    ),
                  );
                  if (drawn != null) {
                    setState(
                      () => _order
                        ..clear()
                        ..addAll(drawn),
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (members.length < 2)
              InfoBanner(
                tone: InfoTone.warning,
                message: l10n.arisanAdminNeedMoreMembers,
              ),
            for (final m in members) ...[
              SelectableTile(
                label: m.fullName,
                sublabel: _order.contains(m.id)
                    ? l10n.arisanTurnFormat(
                        _order.indexOf(m.id) + 1,
                        shortMonthYear(
                          DateTime(
                            _start.year,
                            _start.month + _order.indexOf(m.id),
                          ),
                          l10n: l10n,
                        ),
                      )
                    : m.businessName,
                icon: Icons.person_rounded,
                selected: _order.contains(m.id),
                badge: _order.contains(m.id)
                    ? '${_order.indexOf(m.id) + 1}'
                    : null,
                badgeColor: AppColors.primary,
                onTap: () => setState(() {
                  _order.contains(m.id)
                      ? _order.remove(m.id)
                      : _order.add(m.id);
                }),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref
          .read(actionsProvider)
          .createGroup(
            name: _name.text,
            contributionIdr: parseDigits(_amount.text)!,
            startMonth: _start,
            memberIds: _order,
          ),
      success: AppLocalizations.of(context).arisanAdminGroupCreatedToast,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.pop();
  }
}

/// A fair, transparent random draw for turn order: every selected member is
/// drawn exactly once, revealed one at a time, so the admin (and anyone
/// watching) sees nobody could be drawn twice — the same "once you're
/// drawn, you're out of the pool" guarantee a physical kocok arisan gives.
class _ArisanDrawDialog extends StatefulWidget {
  const _ArisanDrawDialog({required this.memberIds, required this.nameOf});

  final List<String> memberIds;
  final String Function(String) nameOf;

  @override
  State<_ArisanDrawDialog> createState() => _ArisanDrawDialogState();
}

class _ArisanDrawDialogState extends State<_ArisanDrawDialog> {
  late List<String> _drawn;
  final List<String> _revealed = [];
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _drawn = drawArisanOrder(widget.memberIds);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    var i = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 550), (t) {
      if (i >= _drawn.length) {
        t.cancel();
        setState(() => _done = true);
        return;
      }
      setState(() => _revealed.add(_drawn[i]));
      i++;
    });
  }

  void _redraw() {
    setState(() {
      _drawn = drawArisanOrder(widget.memberIds);
      _revealed.clear();
      _done = false;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(l10n.arisanDrawDialogTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.arisanDrawHint, style: text.bodySmall),
            const SizedBox(height: AppSpacing.md),
            for (int i = 0; i < _revealed.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        '${i + 1}',
                        style: text.labelSmall?.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(widget.nameOf(_revealed[i]))),
                  ],
                ),
              ),
            if (!_done) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.arisanDrawInProgress, style: text.bodySmall),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.arisanDrawCancel),
        ),
        if (_done) ...[
          TextButton(onPressed: _redraw, child: Text(l10n.arisanDrawRedo)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_drawn),
            child: Text(l10n.arisanDrawConfirm),
          ),
        ],
      ],
    );
  }
}
