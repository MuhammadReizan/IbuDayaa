import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/app_data_controller.dart';
import '../../../core/data/derived_providers.dart';
import '../../../core/data/insights.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';

/// Things worth acting on, each one derived from the user's own records rather
/// than pushed from anywhere. Dismissing one only hides it until the underlying
/// situation changes.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(observationsProvider);
    final read = ref.watch(dataProvider).readNotificationIds;
    final text = Theme.of(context).textTheme;
    final unread = all.where((o) => !read.contains(o.id)).toList();

    return AppScaffold(
      title: 'Pemberitahuan',
      onBack: () => context.pop(),
      actions: [
        if (unread.isNotEmpty)
          TextButton(
            onPressed: () => ref
                .read(appDataProvider.notifier)
                .markNotificationsRead(all.map((o) => o.id)),
            child: const Text('Tandai dibaca'),
          ),
      ],
      body: all.isEmpty
          ? const EmptyState(
              motif: BrandArtMotif.inbox,
              title: 'Tidak ada yang perlu ditindak',
              message:
                  'Catatan Anda sedang rapi. Kalau ada pemakaian yang melonjak '
                  'atau tagihan yang belum dicatat, muncul di sini.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < all.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _Row(
                    observation: all[i],
                    read: read.contains(all[i].id),
                    onTap: () {
                      ref.read(appDataProvider.notifier).markNotificationsRead([
                        all[i].id,
                      ]);
                      final route = all[i].route;
                      if (route != null) context.push(route);
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    'Semua pemberitahuan dibuat dari catatan Anda sendiri.',
                    style: text.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.observation,
    required this.read,
    required this.onTap,
  });

  final PowerObservation observation;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final ({IconData icon, BadgeTone tone}) s = switch (observation.severity) {
      'danger' => (icon: Icons.trending_up_rounded, tone: BadgeTone.alert),
      'warning' => (icon: Icons.bolt_rounded, tone: BadgeTone.solar),
      'schedule' => (icon: Icons.schedule_rounded, tone: BadgeTone.mint),
      _ => (icon: Icons.info_outline_rounded, tone: BadgeTone.sky),
    };

    return Opacity(
      opacity: read ? 0.62 : 1,
      child: SectionCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FeatureBadge(icon: s.icon, tone: s.tone),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    observation.title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: read ? FontWeight.w600 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(observation.body, style: text.bodySmall),
                ],
              ),
            ),
            if (!read) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
