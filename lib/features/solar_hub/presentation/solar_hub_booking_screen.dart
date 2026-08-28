import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/demo/demo_providers.dart';
import '../../../core/demo/demo_scenario.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../application/solar_hub_providers.dart';

/// SC-06: Solar Hub Booking (docs/SCREEN_INVENTORY.md §SC-06)
class SolarHubBookingScreen extends ConsumerStatefulWidget {
  const SolarHubBookingScreen({super.key});

  @override
  ConsumerState<SolarHubBookingScreen> createState() =>
      _SolarHubBookingScreenState();
}

class _SolarHubBookingScreenState extends ConsumerState<SolarHubBookingScreen> {
  DemoAppliance? _selectedAppliance;
  DemoSolarSlot? _selectedSlot;
  bool _isSubmitting = false;

  IconData _getApplianceIcon(String kind) {
    if (kind == 'oven') return Icons.microwave_outlined;
    if (kind == 'sewingMachine') return Icons.settings_applications_outlined;
    if (kind == 'refrigerator') return Icons.kitchen_outlined;
    if (kind == 'blender') return Icons.blender_outlined;
    return Icons.electrical_services_outlined;
  }

  Future<void> _submitBooking() async {
    if (_selectedAppliance == null || _selectedSlot == null) return;

    setState(() => _isSubmitting = true);

    await Future<void>.delayed(AppDurations.normal);

    if (!mounted) return;

    final booking = DemoSolarBooking(
      id: 'BKG-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      applianceKind: _selectedAppliance!.kind,
      applianceName: _selectedAppliance!.name,
      slotId: _selectedSlot!.id,
      slotLabel: _selectedSlot!.label,
      date: ref.read(demoRepositoryProvider).current.meta.generatedAt,
      createdAt: DateTime.now(),
    );

    ref.read(demoRepositoryProvider).addBooking(booking);

    setState(() => _isSubmitting = false);

    // Pass booking ID or just let SC-07 fetch latest
    context.pushReplacement(AppRoute.bookingConfirmed, extra: booking);
  }

  @override
  Widget build(BuildContext context) {
    final DemoSolarDay day = ref.watch(solarDayProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final bool canSubmit = _selectedAppliance != null && _selectedSlot != null;

    if (_isSubmitting) {
      return const AppScaffold(
        body: LoadingState(label: 'Memproses booking...'),
      );
    }

    return AppScaffold(
      title: 'Booking Solar Hub',
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: 'Booking Sekarang',
        onPressed: canSubmit ? _submitBooking : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kapasitas Energi Hari Ini', style: text.titleMedium),
                    Text(
                      '${day.capacityPct}%',
                      style: text.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: day.capacityPct / 100.0,
                  backgroundColor: AppColors.primaryContainer,
                  color: AppColors.primary,
                  minHeight: 8,
                  borderRadius: AppRadius.pillBr,
                ),
                const SizedBox(height: AppSpacing.sm),
                const QualifierLabel(QualifierKind.simulasi),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('1. Pilih Alat', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...day.appliances.map(
            (app) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SelectableTile(
                icon: _getApplianceIcon(app.kind),
                label: app.name,
                sublabel: '~${app.approxPowerKw} kW',
                selected: _selectedAppliance?.kind == app.kind,
                onTap: () {
                  setState(() => _selectedAppliance = app);
                },
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('2. Pilih Waktu Booking', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (_selectedAppliance != null) ...[
            InfoBanner(
              tone: InfoTone.success,
              icon: Icons.lightbulb_outline,
              message: day.recommendationReason,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          ...day.slots.map((slot) {
            final bool isRecommended = slot.id == day.recommendedSlotId;
            final bool isFull = slot.availability == 'full';

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SelectableTile(
                icon: Icons.access_time_outlined,
                label: slot.label,
                selected: _selectedSlot?.id == slot.id,
                disabled: isFull,
                badge: isFull
                    ? 'Penuh'
                    : (isRecommended ? 'Rekomendasi' : null),
                badgeColor: isFull ? AppColors.danger : AppColors.success,
                onTap: () {
                  if (!isFull) {
                    setState(() => _selectedSlot = slot);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
