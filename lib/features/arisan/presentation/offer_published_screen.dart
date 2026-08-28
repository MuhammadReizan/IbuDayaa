import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';

/// SC-15: Kuota Berhasil Dibagikan
class OfferPublishedScreen extends StatelessWidget {
  const OfferPublishedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Berhasil',
      bottomBar: PrimaryButton(
        label: 'Kembali ke Arisan',
        onPressed: () {
          // Pop back to Arisan screen
          context.pop();
        },
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: AppColors.success),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Kuota Berhasil Dibagikan!',
              style: text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Terima kasih telah berbagi dengan komunitas.',
              style: text.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
