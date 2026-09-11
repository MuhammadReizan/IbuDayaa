import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/db/row.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/format.dart';
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
    final roof = data.latestRoofOf(me.id);

    return AppScaffold(
      title: 'Solar Hub',
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
                        hub?.name ?? 'Solar Hub koperasi',
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
                    'Admin koperasi belum mengatur kapasitas hub. Booking akan '
                    'dibuka setelah kapasitas diisi.',
                    style: text.bodyMedium?.copyWith(color: Colors.white),
                  )
                else ...[
                  Text(
                    'Kapasitas energi hari ini',
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
                            'tersedia · ${formatKwh(day.remainingKwh)} dari '
                            '${formatKwh(day.capacityKwh)}',
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
                  label: 'Booking Jadwal',
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
                      Text('Kuota energi bulan ini', style: text.bodySmall),
                      Text(
                        '${formatKwh(quota.availableKwh)} tersisa',
                        style: text.titleMedium,
                      ),
                      Text(
                        'Jatah ${formatKwh(quota.allocationKwh)} · terpakai '
                        '${formatKwh(quota.bookedKwh)}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Tukar',
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
            const SectionHeader(title: 'Slot hari ini'),
            for (final a in slots) ...[
              _SlotRow(availability: a, passed: now.hour >= a.slot.endHour),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              'Kapasitas per slot dibagi mengikuti perkiraan terik matahari '
              '06.00–18.00: slot siang mendapat bagian lebih besar.',
              style: text.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            title: 'Jadwal saya',
            actionLabel: 'Semua',
            onAction: () => context.push(Paths.bookings),
          ),
          if (upcoming.isEmpty)
            Text('Belum ada jadwal yang akan datang.', style: text.bodyMedium)
          else
            for (final b in upcoming.take(3)) ...[
              TintedRow(
                icon: Icons.event_rounded,
                tone: PillTone.info,
                title:
                    '${formatShortDayDate(b.bookingDate)} · '
                    '${data.slot(b.slotId)?.label ?? ''}',
                subtitle: '${b.applianceName} · ${formatKwh(b.estKwh)}',
                onTap: () => context.push(Paths.bookings),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            tone: CardTone.mint,
            onTap: () => context.push(Paths.roof),
            child: Row(
              children: [
                const BrandArt(motif: BrandArtMotif.roof, size: 64),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Radar Atap', style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        roof == null
                            ? 'Foto dan ukur atap usaha Anda untuk melihat '
                                  'potensi panel surya sendiri.'
                            : 'Terakhir: ${roof.band} · ${roof.estKwp.toStringAsFixed(1)} kWp '
                                  '· hemat ± ${formatRupiah(roof.estMonthlySavingIdr)}/bulan',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
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
                  ? const StatusPill(label: 'Lewat')
                  : a.isFull
                  ? const StatusPill(label: 'Penuh', tone: PillTone.danger)
                  : Text(formatKwh(a.remainingKwh), style: text.labelMedium),
            ),
          ),
        ],
      ),
    );
  }
}
