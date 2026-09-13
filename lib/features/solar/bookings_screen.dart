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
import '../shared/labels.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final today = dayOf(ref.read(clockProvider)());
    final all = s.data.bookingsOf(me.id);
    final upcoming = all.where((b) => b.status == BookingStatus.booked).toList()
      ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
    final history = all.where((b) => b.status != BookingStatus.booked).toList();
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    Widget list(List<HubBooking> items, String empty) => items.isEmpty
        ? EmptyState(
            motif: BrandArtMotif.solar,
            title: empty,
            action: SecondaryButton(
              label: l10n.solarBook,
              expand: false,
              onPressed: () => context.push(Paths.booking),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => i == items.length
                ? Text(
                    l10n.solarSlotCapacityNote,
                    style: text.bodySmall,
                    textAlign: TextAlign.center,
                  )
                : _BookingCard(booking: items[i], today: today),
          );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(l10n.scaffoldBookings),
          leading: IconButton(
            tooltip: l10n.actionBack,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryDark,
            indicatorColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            tabs: [
              Tab(text: '${l10n.solarMyBookings} (${upcoming.length})'),
              Tab(text: l10n.arisanHistory),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            list(upcoming, l10n.solarNoUpcoming),
            list(history, l10n.solarNoUpcoming),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking, required this.today});

  final HubBooking booking;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStateProvider).data;
    final me = ref.watch(appStateProvider).me!;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final b = booking;
    final canConfirm =
        b.status == BookingStatus.booked && !b.bookingDate.isAfter(today);
    final overdue =
        b.status == BookingStatus.booked && b.bookingDate.isBefore(today);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FeatureBadge(
                icon: Icons.event_rounded,
                tone: overdue ? BadgeTone.solar : BadgeTone.mint,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatShortDayDate(b.bookingDate, l10n: l10n)} · ${data.slot(b.slotId)?.label ?? ''}',
                      style: text.titleSmall,
                    ),
                    Text(
                      '${b.applianceName} · ${formatKwh(b.estKwh)} · ± '
                      '${formatRupiah(b.estKwh * me.tariffIdrPerKwh)}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: overdue
                    ? l10n.labelPending
                    : b.status.localizedLabel(l10n),
                tone: overdue ? PillTone.warning : bookingTone(b.status),
              ),
            ],
          ),
          if (b.status == BookingStatus.booked) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: l10n.actionCancel,
                    onPressed: () async {
                      final ok = await confirmDialog(
                        context,
                        title: l10n.actionCancel,
                        message: l10n.solarBookingTitle,
                        confirmLabel: l10n.actionCancel,
                        destructive: true,
                      );
                      if (!ok || !context.mounted) return;
                      await runAction(
                        context,
                        () => ref
                            .read(actionsProvider)
                            .setBookingStatus(b.id, BookingStatus.cancelled),
                        success: 'Booking cancelled.',
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: l10n.labelCompleted,
                    onPressed: canConfirm
                        ? () => runAction(
                            context,
                            () => ref
                                .read(actionsProvider)
                                .setBookingStatus(
                                  b.id,
                                  BookingStatus.completed,
                                ),
                            success: 'Recorded.',
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
