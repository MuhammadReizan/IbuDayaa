import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/row.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
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
  late final _weatherCode = TextEditingController(
    text: _hub?.weatherAdm4Code ?? '',
  );
  late final _maxLoad = TextEditingController(
    text: (_hub?.maxLoadKw ?? 0) > 0 ? decimalText(_hub!.maxLoadKw) : '',
  );
  final _kwp = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _location,
      _capacity,
      _quota,
      _weatherCode,
      _maxLoad,
      _kwp,
    ]) {
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
          maxLoadKw: parseDecimal(_maxLoad.text) ?? 0,
          weatherAdm4Code: _weatherCode.text.trim(),
        ),
      );
      final latest = ref.read(appStateProvider).data.cooperative ?? coop;
      await actions.updateCooperative(
        latest.copyWith(memberMonthlyQuotaKwh: parseDecimal(_quota.text)),
      );
    }, success: AppLocalizations.of(context).adminSettingsSave);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _addSlot(SolarHub hub) async {
    final l10n = AppLocalizations.of(context);
    int start = 8;
    int end = 10;
    final picked = await showDialog<(int, int)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(l10n.hubAddSlotDialogTitle),
          content: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: start,
                  decoration: InputDecoration(labelText: l10n.hubSlotStart),
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
                  decoration: InputDecoration(labelText: l10n.hubSlotEnd),
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
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(kMinTapTarget, kMinTapTarget),
              ),
              onPressed: () => Navigator.of(ctx).pop((start, end)),
              child: Text(l10n.actionAdd),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await runAction(
      context,
      () => ref.read(actionsProvider).addSlot(hub.id, picked.$1, picked.$2),
      success: l10n.hubSlotAddedToast,
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
        body: EmptyState(title: l10n.hubNotFound),
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
      title: l10n.adminHubTitle,
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: l10n.adminSettingsSave,
        loading: _busy,
        onPressed: _save,
      ),
      body: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: l10n.hubFieldName,
              controller: _name,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.hubFieldNameRequired : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: l10n.hubFieldLocation, controller: _location),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.hubFieldCapacity,
              controller: _capacity,
              suffixText: 'kWh',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [decimalInput],
              helper: l10n.hubFieldCapacityHelper,
              validator: (v) => parseDecimal(v ?? '') == null
                  ? l10n.hubFieldCapacityRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            SectionCard(
              tone: CardTone.solar,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.hubCapacityUnknownTitle, style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _kwp,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [decimalInput],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l10n.hubCapacityHint,
                      suffixText: 'kWp',
                    ),
                  ),
                  if (suggested != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.hubCapacitySuggestion(formatKwh(suggested)),
                            style: text.bodySmall?.copyWith(
                              color: AppColors.onSolar,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(
                            () => _capacity.text = decimalText(suggested),
                          ),
                          child: Text(l10n.hubCapacityUse),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.hubFieldMaxLoad,
              controller: _maxLoad,
              suffixText: 'kW',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [decimalInput],
              helper: l10n.hubFieldMaxLoadHelper,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.hubFieldWeatherCode,
              controller: _weatherCode,
              helper: l10n.hubFieldWeatherCodeHelper,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.hubFieldQuota,
              controller: _quota,
              suffixText: 'kWh',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [decimalInput],
              helper: l10n.hubFieldQuotaHelper,
              validator: (v) => (parseDecimal(v ?? '') ?? -1) < 0
                  ? l10n.hubFieldQuotaRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: l10n.hubSlotsSection,
              actionLabel: l10n.actionAdd,
              onAction: () => _addSlot(hub),
            ),
            for (final sl in data.orderedSlots)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TintedRow(
                  icon: Icons.schedule_rounded,
                  tone: PillTone.solar,
                  title: sl.label,
                  subtitle: l10n.hubSlotHours(sl.hours),
                  trailing: IconButton(
                    tooltip: l10n.hubSlotDeleteTooltip,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      final ok = await confirmDialog(
                        context,
                        title: l10n.hubSlotDeleteConfirmTitle(sl.label),
                        message: l10n.hubSlotDeleteConfirmMessage,
                        confirmLabel: l10n.actionDelete,
                        destructive: true,
                      );
                      if (!ok || !context.mounted) return;
                      await runAction(
                        context,
                        () => ref.read(actionsProvider).removeSlot(sl.id),
                        success: l10n.hubSlotDeletedToast,
                      );
                    },
                  ),
                ),
              ),
            if (data.hubRequests.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              TintedRow(
                filled: true,
                tone: PillTone.warning,
                icon: Icons.qr_code_scanner_rounded,
                title: l10n.adminRequestsCardTitle,
                subtitle: '${data.hubRequests.length}',
                onTap: () => context.push(Paths.adminHubRequests),
              ),
            ],
            if (toConfirm.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: l10n.hubBookingsToConfirmSection),
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
                        success: l10n.hubBookingMarkedUsedToast,
                      ),
                      child: Text(l10n.hubBookingMarkUsed),
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
