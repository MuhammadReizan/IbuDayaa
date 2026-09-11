import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';
import '../shared/labels.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final now = ref.read(clockProvider)();
    final items = s.data.notificationsOf(me.id);
    final unread = s.data.unreadNotificationsOf(me.id);
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'Notifikasi',
      onBack: () => context.pop(),
      scrollable: items.isNotEmpty,
      actions: [
        if (unread > 0)
          TextButton(
            onPressed: () => runAction(
              context,
              ref.read(actionsProvider).markAllNotificationsRead,
            ),
            child: const Text('Baca semua'),
          ),
      ],
      body: items.isEmpty
          ? const EmptyState(
              motif: BrandArtMotif.inbox,
              title: 'Belum ada notifikasi',
              message:
                  'Kabar pengajuan, setoran, dan kuota akan muncul di sini.',
            )
          : Column(
              children: [
                for (final n in items) ...[
                  Material(
                    color: n.isRead
                        ? AppColors.surface
                        : AppColors.primaryContainer,
                    borderRadius: AppRadius.smBr,
                    child: InkWell(
                      borderRadius: AppRadius.smBr,
                      onTap: () async {
                        if (!n.isRead) {
                          await ref
                              .read(actionsProvider)
                              .markNotificationRead(n.id);
                        }
                        final route = n.route;
                        if (route != null && context.mounted) {
                          context.push(route);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FeatureBadge(
                              icon: notificationIcon(n.type),
                              size: 40,
                              tone: n.isRead
                                  ? BadgeTone.mint
                                  : BadgeTone.forest,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(n.title, style: text.titleSmall),
                                  const SizedBox(height: 2),
                                  Text(n.body, style: text.bodySmall),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    relativeTimeLabel(n.createdAt, now),
                                    style: text.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}
