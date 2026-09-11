import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/brand/brand.dart';
import '../../../core/data/app_data_controller.dart';
import '../../../core/data/derived_providers.dart';
import '../../../core/data/models.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/energy.dart';
import '../../../core/format/money.dart';

/// The user's arisan circle: who is in it, what has been paid, and whose turn
/// it was. An append-only record they keep themselves — no server, no
/// blockchain, just a shared book that cannot quietly change.
class ArisanScreen extends ConsumerWidget {
  const ArisanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(arisanProvider);
    final ledger = ref.watch(ledgerProvider);
    final text = Theme.of(context).textTheme;

    if (group == null) {
      return AppScaffold(
        title: 'Arisan Energi',
        body: EmptyState(
          motif: BrandArtMotif.community,
          title: 'Belum ada grup arisan',
          message:
              'Buat grup arisan Anda untuk mencatat iuran, giliran, dan '
              'berbagi kuota energi antaranggota.',
          action: PrimaryButton(
            label: 'Buat Grup Arisan',
            expand: false,
            onPressed: () => context.push(AppRoute.arisanCreatePath),
          ),
        ),
      );
    }

    final paidThisMonth = _paidThisMonth(ledger, group);
    final collected = ledger
        .where((e) => e.type == 'contribution')
        .fold<int>(0, (s, e) => s + (e.amountIdr ?? 0));
    final paidOut = ledger
        .where((e) => e.type == 'payout')
        .fold<int>(0, (s, e) => s + (e.amountIdr ?? 0));

    return AppScaffold(
      title: 'Arisan Energi',
      actions: [
        IconButton(
          tooltip: 'Berbagi kuota',
          icon: const Icon(Icons.swap_horiz_rounded),
          onPressed: () => context.push(AppRoute.quotaTradingPath),
        ),
      ],
      bottomBar: PrimaryButton(
        icon: Icons.add_rounded,
        label: 'Catat Transaksi',
        onPressed: () => _recordSheet(context, ref, group),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: AppSpacing.hero,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: AppRadius.lgBr,
              boxShadow: AppShadows.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: text.titleLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                    _Pill(
                      label: paidThisMonth ? 'Lunas' : 'Belum bayar',
                      positive: paidThisMonth,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _AvatarStack(members: group.members),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${group.members.length} anggota · '
                      '${formatRupiah(group.contributionIdr)}/bulan',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textOnDarkDim,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: AppRadius.smBr,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.savings_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Terkumpul ${formatRupiah(collected)} · '
                          'tersalur ${formatRupiah(paidOut)}',
                          style: text.bodySmall?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Row(
            children: [
              Expanded(child: Text('Anggota', style: text.titleMedium)),
              TextButton(
                onPressed: () => _addMemberDialog(context, ref),
                child: const Text('Tambah'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            child: Column(
              children: [
                for (int i = 0; i < group.members.length; i++) ...[
                  if (i > 0) const Divider(height: AppSpacing.lg),
                  _MemberRow(
                    member: group.members[i],
                    paid: _memberPaidThisMonth(ledger, group.members[i]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Catatan Transaksi', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (ledger.isEmpty)
            SectionCard(
              child: Text(
                'Belum ada transaksi. Catat setoran iuran atau pencairan '
                'giliran lewat tombol di bawah.',
                style: text.bodyMedium,
              ),
            )
          else
            for (int i = 0; i < ledger.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _LedgerRow(entry: ledger[i]),
            ],
        ],
      ),
    );
  }

  static bool _paidThisMonth(List<LedgerEntry> ledger, ArisanGroup group) {
    final me = group.members.where((m) => m.isMe).toList();
    if (me.isEmpty) return false;
    return _memberPaidThisMonth(ledger, me.first);
  }

  static bool _memberPaidThisMonth(
    List<LedgerEntry> ledger,
    ArisanMember member,
  ) {
    final now = DateTime.now();
    return ledger.any(
      (e) =>
          e.type == 'contribution' &&
          e.memberId == member.id &&
          e.at.year == now.year &&
          e.at.month == now.month,
    );
  }

  Future<void> _addMemberDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah anggota'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nama anggota'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) {
      await ref.read(appDataProvider.notifier).addArisanMember(name);
    }
  }

  Future<void> _recordSheet(
    BuildContext context,
    WidgetRef ref,
    ArisanGroup group,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RecordSheet(group: group),
  );
}

// ---------------------------------------------------------------------------

class _RecordSheet extends ConsumerStatefulWidget {
  const _RecordSheet({required this.group});
  final ArisanGroup group;

  @override
  ConsumerState<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<_RecordSheet> {
  String _type = 'contribution';
  ArisanMember? _member;
  late final TextEditingController _amount = TextEditingController(
    text: widget.group.contributionIdr.toString(),
  );
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _member =
        widget.group.members.where((m) => m.isMe).firstOrNull ??
        widget.group.members.firstOrNull;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final member = _member;
    final amount = int.tryParse(
      _amount.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (member == null || amount == null || amount <= 0 || _saving) return;

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    await ref
        .read(appDataProvider.notifier)
        .recordLedger(type: _type, member: member, amountIdr: amount);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        AppSpacing.lg,
        20,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Catat Transaksi', style: text.titleLarge),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Setoran iuran'),
                  selected: _type == 'contribution',
                  onSelected: (_) => setState(() {
                    _type = 'contribution';
                    _amount.text = widget.group.contributionIdr.toString();
                  }),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Pencairan giliran'),
                  selected: _type == 'payout',
                  onSelected: (_) => setState(() {
                    _type = 'payout';
                    _amount.text = widget.group.potIdr.toString();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Anggota', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            value: _member?.id,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
            items: [
              for (final m in widget.group.members)
                DropdownMenuItem(
                  value: m.id,
                  child: Text(m.isMe ? '${m.name} (Anda)' : m.name),
                ),
            ],
            onChanged: (v) => setState(
              () => _member = widget.group.members
                  .where((m) => m.id == v)
                  .firstOrNull,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Jumlah', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(prefixText: 'Rp '),
          ),
          const SizedBox(height: AppSpacing.xl),

          PrimaryButton(label: 'Simpan', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.positive});
  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppRadius.pillBr,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members});
  final List<ArisanMember> members;

  @override
  Widget build(BuildContext context) {
    final show = members.take(4).toList();
    return SizedBox(
      height: 30,
      width: 30.0 + (show.length - 1) * 20,
      child: Stack(
        children: [
          for (int i = 0; i < show.length; i++)
            Positioned(
              left: i * 20.0,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                child: MemberAvatar(name: show[i].name, size: 26),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.paid});
  final ArisanMember member;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        MemberAvatar(name: member.name, size: 34),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            member.isMe ? '${member.name} (Anda)' : member.name,
            style: text.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          paid ? 'Lunas bulan ini' : 'Belum',
          style: text.labelSmall?.copyWith(
            color: paid ? AppColors.success : AppColors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LedgerRow extends ConsumerWidget {
  const _LedgerRow({required this.entry});
  final LedgerEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    final ({IconData icon, BadgeTone tone, String label}) meta =
        switch (entry.type) {
          'contribution' => (
            icon: Icons.savings_outlined,
            tone: BadgeTone.mint,
            label: 'Setoran iuran',
          ),
          'payout' => (
            icon: Icons.account_balance_wallet_outlined,
            tone: BadgeTone.solar,
            label: 'Pencairan giliran',
          ),
          'quotaShared' => (
            icon: Icons.north_east_rounded,
            tone: BadgeTone.sky,
            label: 'Membagikan kuota',
          ),
          'quotaReceived' => (
            icon: Icons.south_west_rounded,
            tone: BadgeTone.sky,
            label: 'Menerima kuota',
          ),
          _ => (
            icon: Icons.receipt_long_outlined,
            tone: BadgeTone.mint,
            label: entry.type,
          ),
        };

    final amount = entry.amountIdr != null
        ? formatRupiah(entry.amountIdr!)
        : (entry.amountKwh != null ? formatKwh(entry.amountKwh!) : '');

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          FeatureBadge(icon: meta.icon, tone: meta.tone, size: 38),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.memberName,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${meta.label} · ${formatShortDate(entry.at)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(amount, style: text.titleSmall),
          IconButton(
            tooltip: 'Hapus',
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textTertiary,
            ),
            onPressed: () =>
                ref.read(appDataProvider.notifier).deleteLedgerEntry(entry.id),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
