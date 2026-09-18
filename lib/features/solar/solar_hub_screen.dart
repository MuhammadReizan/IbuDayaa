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
import '../../core/weather/weather_models.dart';
import '../../core/weather/weather_providers.dart';
import '../../core/weather/weather_service.dart';

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
    final request = data.latestHubRequestOf(me.id, now);
    final upcoming =
        data
            .bookingsOf(me.id)
            .where(
              (b) =>
                  (b.status == BookingStatus.booked ||
                      b.status == BookingStatus.pendingVerification) &&
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
          if (request != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TintedRow(
              filled: true,
              tone: switch (request.status) {
                BookingStatus.pendingVerification => PillTone.warning,
                BookingStatus.cancelled => PillTone.neutral,
                _ => PillTone.success,
              },
              icon: switch (request.status) {
                BookingStatus.pendingVerification =>
                  Icons.hourglass_top_rounded,
                BookingStatus.cancelled => Icons.close_rounded,
                _ => Icons.bolt_rounded,
              },
              title: switch (request.status) {
                BookingStatus.pendingVerification => l10n.hubConnectSentTitle,
                BookingStatus.booked => l10n.hubConnectApprovedTitle,
                BookingStatus.completed => l10n.hubConnectDoneTitle,
                BookingStatus.cancelled => l10n.hubConnectRejectedTitle,
              },
              subtitle: request.applianceName,
              onTap: () => context.push(Paths.hubConnect),
            ),
          ],
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SecondaryButton(
                  label: l10n.hubConnectCta,
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: hub?.isConfigured ?? false
                      ? () => context.push(Paths.hubConnect)
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
          const SizedBox(height: AppSpacing.lg),
          if (hub != null &&
              hub.isConfigured &&
              (hub.weatherAdm4Code ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _WeatherOutlookCard(
              adm4Code: hub.weatherAdm4Code!.trim(),
              now: now,
              capacityKwh: hub.dailyCapacityKwh,
            ),
          ],
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
                  : !a.isOpen
                  ? StatusPill(
                      label: l10n.solarSlotClosed,
                      tone: PillTone.neutral,
                    )
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

class _WeatherOutlookCard extends ConsumerWidget {
  const _WeatherOutlookCard({
    required this.adm4Code,
    required this.now,
    required this.capacityKwh,
  });

  final String adm4Code;
  final DateTime now;

  /// The hub's rated daily capacity (a clear-day figure).
  final double capacityKwh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(solarOutlookProvider(adm4Code)).value;
    if (result == null) return const SizedBox.shrink();
    final today = result.today;
    final tomorrow = result.tomorrow;
    if (today == null && tomorrow == null) return const SizedBox.shrink();

    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    String hh(DateTime t) => t.hour.toString().padLeft(2, '0');
    String windowOf(SolarOutlook o) =>
        '${hh(o.windowStart)}.00–${hh(o.windowEnd)}.00';
    // The rule only ever picks one window per day, so once it's over there
    // is nothing left to recommend today — say so instead of still showing
    // it as if it were live and actionable, and point at tomorrow's window
    // (BMKG's forecast already covers it) if there is one.
    final passed = today == null || !today.windowEnd.isAfter(now);
    // Whichever day is still actionable drives the headline number and the
    // cloud-cover reason underneath it.
    final highlight = passed ? tomorrow : today;

    return SectionCard(
      tone: CardTone.solar,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passed && tomorrow == null
                    ? Icons.history_rounded
                    : Icons.wb_sunny_rounded,
                color: AppColors.onSolar,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  passed
                      ? (tomorrow != null
                            ? l10n.solarWeatherTomorrowTitle
                            : l10n.solarWeatherPassedTitle)
                      : l10n.solarWeatherTitle,
                  style: text.titleSmall?.copyWith(color: AppColors.onSolar),
                ),
              ),
              const QualifierLabel(QualifierKind.dataLangsung),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (highlight != null)
            Text(
              windowOf(highlight),
              style: AppTypography.numeric(22, color: AppColors.onSolar),
            ),
          if (highlight != null) ...[
            const SizedBox(height: 2),
            Text(
              l10n.solarWeatherReason(
                highlight.cloudCoverPct,
                highlight.condition,
              ),
              style: text.bodySmall?.copyWith(color: AppColors.onSolar),
            ),
          ],
          if (highlight != null) ...[
            const SizedBox(height: 2),
            Text(
              l10n.solarWeatherScore(
                highlight.productionScore,
                highlight.temperatureC.round(),
              ),
              style: text.bodySmall?.copyWith(color: AppColors.onSolar),
            ),
            if (capacityKwh > 0) ...[
              const SizedBox(height: 2),
              Text(
                l10n.solarWeatherCapacity(
                  (highlight.capacityFactor * 100).round(),
                  formatKwh(capacityKwh * highlight.capacityFactor),
                  formatKwh(capacityKwh),
                ),
                style: text.bodySmall?.copyWith(color: AppColors.onSolar),
              ),
            ],
            if (isRainy(highlight.condition)) ...[
              const SizedBox(height: 2),
              Text(
                l10n.solarWeatherRainNote,
                style: text.bodySmall?.copyWith(color: AppColors.onSolar),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.solarWeatherSource,
            style: text.labelSmall?.copyWith(color: AppColors.onSolar),
          ),
          if (passed && tomorrow == null) ...[
            const SizedBox(height: 2),
            Text(
              l10n.solarWeatherPassedHint,
              style: text.labelSmall?.copyWith(color: AppColors.onSolar),
            ),
          ],
        ],
      ),
    );
  }
}
