import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_scenario.dart';
import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../application/messages_providers.dart';

/// SC-16: Pesan (Daftar Thread)
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<DemoMessageThread> threads = ref.watch(messageThreadsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    // scrollable: false — the body is a ListView, which must get a bounded
    // height from the Scaffold rather than an unbounded one from a
    // SingleChildScrollView.
    return AppScaffold(
      title: 'Pesan',
      scrollable: false,
      padding: EdgeInsets.zero,
      body: threads.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Belum Ada Pesan',
              message: 'Pesan dari komunitas atau admin akan muncul di sini.',
            )
          : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: threads.length,
              itemBuilder: (context, index) {
                final thread = threads[index];
                return _ThreadTile(thread: thread, text: text);
              },
            ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.text});

  final DemoMessageThread thread;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final isUnread = thread.unreadCount > 0;

    IconData icon;
    Color iconColor;
    switch (thread.kind) {
      case 'group':
        icon = Icons.group_outlined;
        iconColor = AppColors.primary;
        break;
      case 'admin':
        icon = Icons.admin_panel_settings_outlined;
        iconColor = AppColors.warning;
        break;
      case 'system':
        icon = Icons.lightbulb_outline;
        iconColor = AppColors.info;
        break;
      default:
        icon = Icons.person_outline;
        iconColor = AppColors.textSecondary;
    }

    return InkWell(
      onTap: () {
        // SC-17 Read-only thread view would go here. Not requested in P0.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Detail pesan belum tersedia di versi demo ini.'),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.outline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.1),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          thread.title,
                          style: text.titleSmall?.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(thread.lastAt),
                        style: text.bodySmall?.copyWith(
                          color: isUnread
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isUnread ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    thread.lastPreview,
                    style: text.bodyMedium?.copyWith(
                      color: isUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: isUnread ? FontWeight.w600 : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  thread.unreadCount.toString(),
                  style: text.labelSmall?.copyWith(color: AppColors.surface),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime(2026, 8, 1); // Relative to demo seed time
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
