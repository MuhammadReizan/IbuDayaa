import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/row.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logic/hub_capacity.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';

class SolarHubScreen extends ConsumerWidget {
  const SolarHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final hub = data.hub;
    final now = ref.read(clockProvider)();
    final today = dayOf(now);
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final slots = data.availabilityOn(today);
    final day = dayCapacity(slots);
    final quota = data.quotaOf(me.id, now);
    final upcoming =
        data
            .bookingsOf(me.id)
            .where(
              (b) =>
                  b.status == BookingStatus.booked &&
                  !b.bookingDate.isBefore(today),
            )
            .toList()
          ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

    return AppScaffold(
      title: l10n.solarTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.solar_power_rounded,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        hub?.name ?? l10n.solarHubCoop,
                        style: text.titleMedium?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if ((hub?.location ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    hub!.location,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textOnDarkDim,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (hub == null || !hub.isConfigured)
                  Text(
                    l10n.solarNoHubMessage,
                    style: text.bodyMedium?.copyWith(color: Colors.white),
                  )
                else ...[
                  Text(
                    l10n.solarCapacityToday,
                    style: text.labelMedium?.copyWith(
                      color: AppColors.textOnDarkDim,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(day.freeFraction * 100).round()}%',
                        style: AppTypography.numeric(34, color: Colors.white),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            l10n.solarCapacityAvailable(
                              formatKwh(day.remainingKwh),
                              formatKwh(day.capacityKwh),
                            ),
                            style: text.bodySmall?.copyWith(
                              color: AppColors.textOnDarkDim,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppProgressBar(
                    value: day.freeFraction,
                    color: AppColors.secondary,
                    track: Colors.white.withValues(alpha: 0.2),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: l10n.solarBookingScheduleBtn,
                  icon: Icons.event_available_rounded,
                  onPressed: hub?.isConfigured ?? false
                      ? () => context.push(Paths.booking)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            onTap: () => context.push(Paths.quota),
            child: Row(
              children: [
                const FeatureBadge(
                  icon: Icons.bolt_rounded,
                  tone: BadgeTone.solar,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.solarQuotaThisMonth, style: text.bodySmall),
                      Text(
                        l10n.solarQuotaRemaining(formatKwh(quota.availableKwh)),
                        style: text.titleMedium,
                      ),
                      Text(
                        l10n.solarQuotaAllocationUsed(
                          formatKwh(quota.allocationKwh),
                          formatKwh(quota.bookedKwh),
                        ),
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.solarSwap,
                  style: text.labelLarge?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryDark,
                ),
              ],
            ),
          ),
          if (hub != null && hub.isConfigured && slots.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: l10n.solarTodaySlots),
            for (final a in slots) ...[
              _SlotRow(availability: a, passed: now.hour >= a.slot.endHour),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(l10n.solarSlotCapacityNote, style: text.bodySmall),
          ],
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            title: l10n.solarMyBookings,
            actionLabel: l10n.solarMyScheduleAll,
            onAction: () => context.push(Paths.bookings),
          ),
          if (upcoming.isEmpty)
            Text(l10n.solarNoUpcoming, style: text.bodyMedium)
          else
            for (final b in upcoming.take(3)) ...[
              TintedRow(
                icon: Icons.event_rounded,
                tone: PillTone.info,
                title:
                    '${formatShortDayDate(b.bookingDate, l10n: l10n)} · '
                    '${data.slot(b.slotId)?.label ?? ''}',
                subtitle: '${b.applianceName} · ${formatKwh(b.estKwh)}',
                onTap: () => context.push(Paths.bookings),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.availability, required this.passed});

  final SlotAvailability availability;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final a = availability;
    final free = 1 - a.usedFraction;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.smBr,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(a.slot.label, style: text.titleSmall),
          ),
          Expanded(
            child: AppProgressBar(
              value: passed ? 0 : free,
              color: free < 0.2 ? AppColors.warning : AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 84,
            child: Align(
              alignment: Alignment.centerRight,
              child: passed
                  ? StatusPill(label: l10n.solarSlotPassed)
                  : a.isFull
                  ? StatusPill(label: l10n.solarSlotFull, tone: PillTone.danger)
                  : Text(formatKwh(a.remainingKwh), style: text.labelMedium),
            ),
          ),
        ],
      ),
    );
  }
}
