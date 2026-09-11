import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/row.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/logic/hub_capacity.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../shared/labels.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, this.applianceName});

  final String? applianceName;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  static const _custom = '__custom__';

  late DateTime _day = dayOf(ref.read(clockProvider)());
  String? _applianceId;
  String? _slotId;
  bool _busy = false;
  HubBooking? _done;
  final _customName = TextEditingController();
  final _customWatts = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = ref.read(appStateProvider);
    final me = s.me;
    if (me == null) return;
    final list = s.data.appliancesOf(me.id);
    final wanted = widget.applianceName?.toLowerCase();
    _applianceId =
        list.where((a) => a.name.toLowerCase() == wanted).firstOrNull?.id ??
        list.firstOrNull?.id ??
        _custom;
  }

  @override
  void dispose() {
    _customName.dispose();
    _customWatts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final hub = data.hub;
    final now = ref.read(clockProvider)();
    final today = dayOf(now);
    final text = Theme.of(context).textTheme;

    final done = _done;
    if (done != null) {
      return SuccessPanel(
        title: 'Booking berhasil',
        message:
            'Datang ke ${hub?.name ?? 'Solar Hub'} sesuai jadwal. Setelah '
            'dipakai, tandai "Sudah dipakai" agar penghematan tercatat.',
        primaryLabel: 'Lihat jadwal saya',
        onPrimary: () => context.pushReplacement(Paths.bookings),
        secondaryLabel: 'Kembali',
        onSecondary: () => context.pop(),
        child: SectionCard(
          child: Column(
            children: [
              KeyValueRow(
                label: 'Tanggal',
                value: formatShortDayDate(done.bookingDate),
              ),
              KeyValueRow(
                label: 'Jam',
                value: data.slot(done.slotId)?.label ?? '-',
              ),
              KeyValueRow(label: 'Alat', value: done.applianceName),
              KeyValueRow(
                label: 'Energi dipesan',
                value: formatKwh(done.estKwh),
              ),
              KeyValueRow(
                label: 'Hemat tagihan PLN',
                value: '± ${formatRupiah(done.estKwh * me.tariffIdrPerKwh)}',
                valueColor: AppColors.primaryDark,
              ),
            ],
          ),
        ),
      );
    }

    if (hub == null || !hub.isConfigured) {
      return AppScaffold(
        title: 'Booking Solar Hub',
        onBack: () => context.pop(),
        scrollable: false,
        body: const EmptyState(
          motif: BrandArtMotif.solar,
          title: 'Booking belum dibuka',
          message: 'Admin koperasi belum mengatur kapasitas Solar Hub.',
        ),
      );
    }

    final appliances = data.appliancesOf(me.id);
    final selected = appliances.where((a) => a.id == _applianceId).firstOrNull;
    final watts = _applianceId == _custom
        ? double.tryParse(_customWatts.text) ?? 0
        : selected?.watts ?? 0;
    final applianceName = _applianceId == _custom
        ? _customName.text.trim()
        : selected?.name ?? '';

    double need(HubSlot slot) => watts / 1000 * slot.hours;
    bool passed(HubSlot slot) =>
        sameDay(_day, today) && now.hour >= slot.endHour;

    final slots = data.availabilityOn(_day);
    final usable = slots
        .where(
          (a) =>
              !passed(a.slot) &&
              watts > 0 &&
              a.remainingKwh + 1e-9 >= need(a.slot),
        )
        .toList();
    SlotAvailability? best;
    for (final a in usable) {
      if (best == null || a.remainingKwh > best.remainingKwh) best = a;
    }
    final chosen = slots.where((a) => a.slot.id == _slotId).firstOrNull;
    final chosenUsable = chosen != null && usable.contains(chosen);
    final quota = data.quotaOf(me.id, _day);
    final estKwh = chosen == null ? 0.0 : need(chosen.slot);

    return AppScaffold(
      title: 'Booking Solar Hub',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: chosenUsable
            ? 'Booking ${chosen.slot.label}'
            : 'Pilih alat dan jam',
        loading: _busy,
        onPressed: chosenUsable && applianceName.isNotEmpty
            ? () => _book(chosen.slot, applianceName, estKwh)
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('1. Pilih tanggal', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 15,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final d = today.add(Duration(days: i));
                final on = sameDay(d, _day);
                return _DateChip(
                  date: d,
                  label: i == 0
                      ? 'Hari ini'
                      : formatShortDayDate(d).split(',').first,
                  selected: on,
                  onTap: () => setState(() {
                    _day = d;
                    _slotId = null;
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('2. Alat yang akan dipakai', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final a in appliances) ...[
            SelectableTile(
              icon: applianceIcon(a.kind),
              label: a.name,
              sublabel: '${a.watts.round()} watt',
              selected: _applianceId == a.id,
              onTap: () => setState(() => _applianceId = a.id),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          SelectableTile(
            icon: Icons.add_rounded,
            label: 'Alat lain',
            sublabel: 'Isi nama dan dayanya',
            selected: _applianceId == _custom,
            onTap: () => setState(() => _applianceId = _custom),
          ),
          if (_applianceId == _custom) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    label: 'Nama alat',
                    controller: _customName,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: 'Daya',
                    controller: _customWatts,
                    suffixText: 'W',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('3. Pilih jam', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (watts <= 0)
            Text(
              'Pilih alat dulu untuk melihat jam yang cukup.',
              style: text.bodyMedium,
            )
          else
            for (final a in slots) ...[
              SelectableTile(
                icon: Icons.schedule_rounded,
                label: a.slot.label,
                sublabel: passed(a.slot)
                    ? 'Sudah lewat'
                    : 'Sisa ${formatKwh(a.remainingKwh)} · butuh ${formatKwh(need(a.slot))}',
                selected: _slotId == a.slot.id,
                disabled: !usable.contains(a),
                badge: identical(a, best)
                    ? 'Paling lega'
                    : (!passed(a.slot) && !usable.contains(a)
                          ? 'Tidak cukup'
                          : null),
                badgeColor: identical(a, best)
                    ? AppColors.primary
                    : AppColors.danger,
                onTap: () => setState(() => _slotId = a.slot.id),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          if (chosenUsable) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              tone: CardTone.mint,
              title: 'Ringkasan',
              child: Column(
                children: [
                  KeyValueRow(
                    label: 'Energi dipesan',
                    value:
                        '${formatKwh(estKwh)} (${watts.round()} W × ${chosen.slot.hours} jam)',
                  ),
                  KeyValueRow(
                    label: 'Hemat tagihan PLN',
                    value: '± ${formatRupiah(estKwh * me.tariffIdrPerKwh)}',
                  ),
                  KeyValueRow(
                    label: 'Sisa kuota setelah booking',
                    value: formatKwh(quota.availableKwh - estKwh),
                    valueColor: quota.availableKwh - estKwh < 0
                        ? AppColors.dangerText
                        : null,
                  ),
                ],
              ),
            ),
            if (quota.availableKwh + 1e-9 < estKwh) ...[
              const SizedBox(height: AppSpacing.sm),
              InfoBanner(
                tone: InfoTone.warning,
                message:
                    'Kuota Anda tidak cukup. Minta kuota ke anggota lain di '
                    'Perdagangan Energi.',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _book(HubSlot slot, String name, double estKwh) async {
    setState(() => _busy = true);
    HubBooking? result;
    await runAction(
      context,
      () async => result = await ref
          .read(actionsProvider)
          .book(
            slotId: slot.id,
            date: _day,
            applianceName: name,
            estKwh: estKwh,
          ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = result;
    });
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fg = selected ? Colors.white : AppColors.textPrimary;
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: AppRadius.smBr,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smBr,
        child: Container(
          width: 72,
          decoration: BoxDecoration(
            borderRadius: AppRadius.smBr,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                style: text.labelSmall?.copyWith(
                  color: selected
                      ? AppColors.textOnDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text('${date.day}', style: text.titleLarge?.copyWith(color: fg)),
              Text(
                monthAbbr(date),
                style: text.labelSmall?.copyWith(
                  color: selected
                      ? AppColors.textOnDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
