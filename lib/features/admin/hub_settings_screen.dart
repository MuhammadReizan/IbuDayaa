import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/row.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../shared/inputs.dart';
import '../shared/labels.dart';

class HubSettingsScreen extends ConsumerStatefulWidget {
  const HubSettingsScreen({super.key});

  @override
  ConsumerState<HubSettingsScreen> createState() => _HubSettingsScreenState();
}

class _HubSettingsScreenState extends ConsumerState<HubSettingsScreen> {
  final _form = GlobalKey<FormState>();
  late final _hub = ref.read(appStateProvider).data.hub;
  late final _coop = ref.read(appStateProvider).data.cooperative;
  late final _name = TextEditingController(text: _hub?.name ?? '');
  late final _location = TextEditingController(text: _hub?.location ?? '');
  late final _capacity = TextEditingController(
    text: (_hub?.dailyCapacityKwh ?? 0) > 0
        ? decimalText(_hub!.dailyCapacityKwh)
        : '',
  );
  late final _quota = TextEditingController(
    text: decimalText(_coop?.memberMonthlyQuotaKwh ?? 30),
  );
  final _kwp = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _location, _capacity, _quota, _kwp]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final hub = _hub;
    final coop = _coop;
    if (hub == null || coop == null || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final actions = ref.read(actionsProvider);
    await runAction(context, () async {
      await actions.updateHub(
        hub.copyWith(
          name: _name.text,
          location: _location.text,
          dailyCapacityKwh: parseDecimal(_capacity.text) ?? 0,
        ),
      );
      final latest = ref.read(appStateProvider).data.cooperative ?? coop;
      await actions.updateCooperative(
        latest.copyWith(memberMonthlyQuotaKwh: parseDecimal(_quota.text)),
      );
    }, success: 'Pengaturan Solar Hub tersimpan.');
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _addSlot(SolarHub hub) async {
    int start = 8;
    int end = 10;
    final picked = await showDialog<(int, int)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Tambah slot'),
          content: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: start,
                  decoration: const InputDecoration(labelText: 'Mulai'),
                  items: [
                    for (int h = 5; h < 19; h++)
                      DropdownMenuItem(
                        value: h,
                        child: Text('${h.toString().padLeft(2, '0')}.00'),
                      ),
                  ],
                  onChanged: (v) => set(() {
                    start = v ?? start;
                    if (end <= start) end = start + 1;
                  }),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: end,
                  decoration: const InputDecoration(labelText: 'Selesai'),
                  items: [
                    for (int h = start + 1; h <= 19; h++)
                      DropdownMenuItem(
                        value: h,
                        child: Text('${h.toString().padLeft(2, '0')}.00'),
                      ),
                  ],
                  onChanged: (v) => set(() => end = v ?? end),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(kMinTapTarget, kMinTapTarget),
              ),
              onPressed: () => Navigator.of(ctx).pop((start, end)),
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await runAction(
      context,
      () => ref.read(actionsProvider).addSlot(hub.id, picked.$1, picked.$2),
      success: 'Slot ditambahkan.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStateProvider).data;
    final hub = data.hub;
    final now = ref.read(clockProvider)();
    final today = dayOf(now);
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    if (hub == null) {
      return AppScaffold(
        title: l10n.adminHubTitle,
        onBack: () => context.pop(),
        scrollable: false,
        body: const EmptyState(title: 'Solar Hub tidak ditemukan'),
      );
    }

    final kwp = parseDecimal(_kwp.text);
    final suggested = kwp == null ? null : kwp * 4 * 0.8;
    final toConfirm =
        data.bookings
            .where(
              (b) =>
                  b.status == BookingStatus.booked &&
                  !b.bookingDate.isAfter(today),
            )
            .toList()
          ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

    return AppScaffold(
      title: 'Solar Hub',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Simpan pengaturan',
        loading: _busy,
        onPressed: _save,
      ),
      body: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Nama hub',
              controller: _name,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Isi nama hub.' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Lokasi', controller: _location),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Kapasitas energi per hari',
              controller: _capacity,
              suffixText: 'kWh',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [decimalInput],
              helper: 'Isi 0 untuk menutup booking sementara.',
              validator: (v) =>
                  parseDecimal(v ?? '') == null ? 'Isi kapasitas.' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            SectionCard(
              tone: CardTone.solar,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Belum tahu kapasitasnya?', style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _kwp,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [decimalInput],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Daya panel terpasang',
                      suffixText: 'kWp',
                    ),
                  ),
                  if (suggested != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '≈ ${formatKwh(suggested)} per hari (kWp × 4 jam matahari × 80%)',
                            style: text.bodySmall?.copyWith(
                              color: AppColors.onSolar,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(
                            () => _capacity.text = decimalText(suggested),
                          ),
                          child: const Text('Pakai'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Kuota tiap anggota per bulan',
              controller: _quota,
              suffixText: 'kWh',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [decimalInput],
              helper:
                  'Batas energi hub yang boleh dibooking satu anggota dalam sebulan.',
              validator: (v) =>
                  (parseDecimal(v ?? '') ?? -1) < 0 ? 'Isi kuota.' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Slot jam',
              actionLabel: 'Tambah',
              onAction: () => _addSlot(hub),
            ),
            for (final sl in data.orderedSlots)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TintedRow(
                  icon: Icons.schedule_rounded,
                  tone: PillTone.solar,
                  title: sl.label,
                  subtitle: '${sl.hours} jam',
                  trailing: IconButton(
                    tooltip: 'Hapus slot',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      final ok = await confirmDialog(
                        context,
                        title: 'Hapus slot ${sl.label}?',
                        message:
                            'Slot yang masih punya booking tidak bisa dihapus.',
                        confirmLabel: 'Hapus',
                        destructive: true,
                      );
                      if (!ok || !context.mounted) return;
                      await runAction(
                        context,
                        () => ref.read(actionsProvider).removeSlot(sl.id),
                        success: 'Slot dihapus.',
                      );
                    },
                  ),
                ),
              ),
            if (toConfirm.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(
                title: 'Booking hari ini & belum dikonfirmasi',
              ),
              for (final b in toConfirm)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: TintedRow(
                    icon: Icons.event_rounded,
                    tone: bookingTone(b.status),
                    title:
                        '${data.nameOf(b.userId)} · ${data.slot(b.slotId)?.label ?? ''}',
                    subtitle:
                        '${formatShortDayDate(b.bookingDate)} · ${b.applianceName} · ${formatKwh(b.estKwh)}',
                    trailing: TextButton(
                      onPressed: () => runAction(
                        context,
                        () => ref
                            .read(actionsProvider)
                            .setBookingStatus(b.id, BookingStatus.completed),
                        success: 'Ditandai sudah dipakai.',
                      ),
                      child: const Text('Dipakai'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
