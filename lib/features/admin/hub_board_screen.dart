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
import '../../core/state/snapshot.dart';
import '../shared/labels.dart';

/// Who is using the hub, slot by slot: energy booked, simultaneous load
/// against the inverter limit, and a switch to close a slot (maintenance, bad
/// weather). Closing stops new bookings; it never cancels existing ones.
class HubBoardScreen extends ConsumerStatefulWidget {
  const HubBoardScreen({super.key});

  @override
  ConsumerState<HubBoardScreen> createState() => _HubBoardScreenState();
}

class _HubBoardScreenState extends ConsumerState<HubBoardScreen> {
  int _dayOffset = 0;

  Future<void> _toggle(HubSlot slot, bool open) async {
    final l10n = AppLocalizations.of(context);
    if (!open) {
      final ok = await confirmDialog(
        context,
        title: l10n.adminBoardCloseTitle(slot.label),
        message: l10n.adminBoardCloseBody,
        confirmLabel: l10n.adminBoardClose,
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    await runAction(
      context,
      () => ref.read(actionsProvider).setSlotOpen(slot.id, open),
      success: open ? l10n.adminBoardOpenedToast : l10n.adminBoardClosedToast,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final data = s.data;
    final hub = data.hub;
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final today = dayOf(ref.read(clockProvider)());
    final day = today.add(Duration(days: _dayOffset));

    if (hub == null || !hub.isConfigured) {
      return AppScaffold(
        title: l10n.adminBoardTitle,
        onBack: () => context.pop(),
        scrollable: false,
        body: EmptyState(
          motif: BrandArtMotif.solar,
          title: l10n.solarNoHub,
          message: l10n.solarNoHubMessage,
        ),
      );
    }

    final slots = data.availabilityOn(day);
    return AppScaffold(
      title: l10n.adminBoardTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: Text(l10n.adminBoardToday),
                selected: _dayOffset == 0,
                onSelected: (_) => setState(() => _dayOffset = 0),
              ),
              ChoiceChip(
                label: Text(l10n.adminBoardTomorrow),
                selected: _dayOffset == 1,
                onSelected: (_) => setState(() => _dayOffset = 1),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!hub.maxLoadKw.isFinite || hub.maxLoadKw <= 0)
            InfoBanner(
              tone: InfoTone.warning,
              message: l10n.adminBoardNoLoadLimit,
            ),
          for (final a in slots) ...[
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(a.slot.label, style: text.titleMedium),
                      ),
                      Text(
                        a.isOpen ? l10n.adminBoardOpen : l10n.adminBoardClosed,
                        style: text.labelMedium,
                      ),
                      Switch(
                        value: a.isOpen,
                        onChanged: (v) => _toggle(a.slot, v),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.adminBoardEnergy(
                      formatKwh(a.bookedKwh),
                      formatKwh(a.capacityKwh),
                    ),
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppProgressBar(value: a.usedFraction),
                  if (a.hasLoadLimit) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.adminBoardLoad(
                        a.loadKw.toStringAsFixed(1),
                        a.maxLoadKw.toStringAsFixed(1),
                      ),
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppProgressBar(
                      value: (a.loadKw / a.maxLoadKw).clamp(0.0, 1.0),
                      color: a.loadKw / a.maxLoadKw > 0.85
                          ? AppColors.warning
                          : AppColors.primary,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  ..._members(context, data, a.slot, day, l10n, text),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _members(
    BuildContext context,
    CoopSnapshot data,
    HubSlot slot,
    DateTime day,
    AppLocalizations l10n,
    TextTheme text,
  ) {
    final list =
        data.bookings
            .where(
              (b) =>
                  b.slotId == slot.id &&
                  b.countsAgainstCapacity &&
                  sameDay(b.bookingDate, day),
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (list.isEmpty) {
      return [Text(l10n.adminBoardNoBookings, style: text.bodySmall)];
    }
    return [
      for (final b in list)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${data.nameOf(b.userId)} · ${b.applianceName}',
                  style: text.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusPill(
                label: b.status.localizedLabel(l10n),
                tone: bookingTone(b.status),
              ),
            ],
          ),
        ),
    ];
  }
}
