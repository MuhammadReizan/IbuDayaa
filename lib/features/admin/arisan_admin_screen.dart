import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/row.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
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

    return AppScaffold(
      title: 'Grup Arisan',
      onBack: () => context.pop(),
      scrollable: data.groups.isNotEmpty,
      bottomBar: PrimaryButton(
        label: 'Buat grup arisan',
        icon: Icons.add_rounded,
        onPressed: () => context.push(Paths.adminArisanNew),
      ),
      body: data.groups.isEmpty
          ? const EmptyState(
              motif: BrandArtMotif.arisan,
              title: 'Belum ada grup arisan',
              message:
                  'Buat grup, pilih anggotanya, dan tentukan urutan giliran.',
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
                              label: 'Iuran per bulan',
                              value: formatRupiah(g.contributionIdr),
                            ),
                            KeyValueRow(
                              label: 'Anggota',
                              value: '${members.length} orang',
                            ),
                            KeyValueRow(
                              label: 'Mulai',
                              value: monthYearLabel(g.startMonth),
                            ),
                            if (started) ...[
                              KeyValueRow(
                                label: 'Lunas bulan ini',
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
                                  message:
                                      'Sudah dicairkan ke ${data.nameOf(payout.userId)} '
                                      '(${formatRupiah(payout.amountIdr)}).',
                                )
                              else if (recipient != null)
                                PrimaryButton(
                                  label:
                                      'Catat pencairan ke ${data.nameOf(recipient.userId)}',
                                  onPressed: () async {
                                    final ok = await confirmDialog(
                                      context,
                                      title: 'Catat pencairan?',
                                      message:
                                          '${formatRupiah(g.contributionIdr * members.length)} diserahkan ke '
                                          '${data.nameOf(recipient.userId)} untuk ${monthYearLabel(now)}.'
                                          '${paid < members.length ? '\n\nPerhatian: baru $paid dari ${members.length} anggota yang lunas.' : ''}',
                                      confirmLabel: 'Catat',
                                    );
                                    if (!ok || !context.mounted) return;
                                    await runAction(
                                      context,
                                      () => ref
                                          .read(actionsProvider)
                                          .recordPayout(g.id, recipient.userId),
                                      success: 'Pencairan dicatat.',
                                    );
                                  },
                                ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            Text('Urutan giliran', style: text.titleSmall),
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
                                        DateTime(
                                          g.startMonth.year,
                                          g.startMonth.month + m.turnOrder - 1,
                                        ),
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
  final _name = TextEditingController(text: 'Arisan Energi');
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
    final members = data.memberProfiles;

    return AppScaffold(
      title: 'Buat Grup Arisan',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Buat grup (${_order.length} anggota)',
        loading: _busy,
        onPressed: _order.length < 2 ? null : _submit,
      ),
      body: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Nama grup',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Isi nama grup.' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Iuran per bulan',
              controller: _amount,
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              inputFormatters: [
                ThousandsFormatter(),
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (v) => (parseDigits(v ?? '') ?? 0) < 1000
                  ? 'Minimal Rp 1.000.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Bulan mulai', style: text.titleSmall),
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
            Text('Pilih anggota sesuai urutan giliran', style: text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Ketuk anggota yang menerima pertama, lalu kedua, dan seterusnya.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (members.length < 2)
              const InfoBanner(
                tone: InfoTone.warning,
                message:
                    'Butuh minimal 2 anggota terdaftar. Bagikan kode koperasi dulu.',
              ),
            for (final m in members) ...[
              SelectableTile(
                label: m.fullName,
                sublabel: _order.contains(m.id)
                    ? 'Giliran ke-${_order.indexOf(m.id) + 1} · '
                          '${shortMonthYear(DateTime(_start.year, _start.month + _order.indexOf(m.id)))}'
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
      success: 'Grup arisan dibuat. Anggota sudah diberi tahu.',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.pop();
  }
}
