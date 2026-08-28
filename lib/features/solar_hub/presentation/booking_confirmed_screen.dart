import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/demo/demo_scenario.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';

/// SC-07: Booking Terkonfirmasi (docs/SCREEN_INVENTORY.md §SC-07)
class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({super.key, required this.booking});

  final DemoSolarBooking booking;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      // No back button; the only way forward is "Kembali ke Beranda", which
      // resets the navigation stack to Home.
      bottomBar: PrimaryButton(
        label: 'Kembali ke Beranda',
        onPressed: () => context.go(AppRoute.homePath),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          const Icon(Icons.check_circle, color: AppColors.success, size: 80),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Booking Terkonfirmasi',
            style: text.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Slot Solar Hub Anda telah tercatat dengan aman.',
            style: text.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailRow(label: 'ID Booking', value: booking.id),
                const Divider(height: AppSpacing.xl, color: AppColors.outline),
                _DetailRow(label: 'Alat', value: booking.applianceName),
                const Divider(height: AppSpacing.xl, color: AppColors.outline),
                _DetailRow(label: 'Jadwal', value: booking.slotLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
