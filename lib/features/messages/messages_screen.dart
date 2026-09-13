import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/brand/brand.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';
import '../../core/paths.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key, this.standalone = false});

  /// Pushed on top (admin) rather than shown as a tab.
  final bool standalone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final now = ref.read(clockProvider)();
    final threads = data.threadsFor(me);
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.messagesTitle,
      onBack: standalone ? () => context.pop() : null,
      scrollable: threads.isNotEmpty,
      actions: [
        IconButton(
          tooltip: l10n.messagesTitle,
          onPressed: () => _newMessage(context, ref, me),
          icon: const Icon(Icons.edit_square),
        ),
      ],
      body: threads.isEmpty
          ? EmptyState(
              motif: BrandArtMotif.inbox,
              title: l10n.messagesEmpty,
              message: l10n.messagesEmptyMessage,
            )
          : Column(
              children: [
                for (final t in threads)
                  _ThreadRow(
                    summary: t,
                    now: now,
                    me: me,
                    senderName:
                        t.last?.senderId == null || t.last!.senderId == me.id
                        ? null
                        : data.nameOf(t.last!.senderId),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.messagesEmptyMessage,
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Future<void> _newMessage(
    BuildContext context,
    WidgetRef ref,
    Profile me,
  ) async {
    final data = ref.read(appStateProvider).data;
    final people = data.members.where((p) => p.id != me.id).toList()
      ..sort((a, b) {
        if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
        return a.fullName.compareTo(b.fullName);
      });
    final picked = await showModalBottomSheet<Profile>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            0,
            AppSpacing.gutter,
            AppSpacing.lg,
          ),
          children: [
            Text(
              AppLocalizations.of(context).threadTitle,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final p in people)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: MemberAvatar(name: p.fullName),
                title: Text(p.fullName),
                subtitle: Text(p.isAdmin ? 'Admin koperasi' : p.businessName),
                onTap: () => Navigator.of(ctx).pop(p),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;

    // Admins and members already share a support thread; reuse it.
    final support = me.isAdmin
        ? data.supportThreadOf(picked.id)
        : picked.isAdmin
        ? data.supportThreadOf(me.id)
        : null;
    if (support != null) {
      context.push(Paths.thread(support.id));
      return;
    }
    String? id;
    final ok = await runAction(
      context,
      () async =>
          id = await ref.read(actionsProvider).openDirectThread(picked.id),
    );
    if (ok && id != null && context.mounted) context.push(Paths.thread(id!));
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    required this.summary,
    required this.now,
    required this.me,
    this.senderName,
  });

  final ThreadSummary summary;
  final DateTime now;
  final Profile me;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = summary;
    final last = t.last;
    final unread = t.unread > 0;

    final Widget avatar = t.avatarName != null
        ? MemberAvatar(name: t.avatarName!, size: 48)
        : FeatureBadge(
            size: 48,
            icon: switch (t.thread.kind) {
              ThreadKind.announcement => Icons.campaign_rounded,
              ThreadKind.group => Icons.groups_rounded,
              ThreadKind.support => Icons.support_agent_rounded,
              ThreadKind.direct => Icons.person_rounded,
            },
            tone: switch (t.thread.kind) {
              ThreadKind.announcement => BadgeTone.solar,
              ThreadKind.group => BadgeTone.mint,
              _ => BadgeTone.sky,
            },
          );

    final preview = last == null
        ? 'Belum ada pesan'
        : last.isSystem
        ? last.body
        : last.senderId == me.id
        ? 'Anda: ${last.body}'
        : senderName != null && t.thread.kind != ThreadKind.direct
        ? '$senderName: ${last.body}'
        : last.body;

    return InkWell(
      onTap: () => context.push(Paths.thread(t.thread.id)),
      borderRadius: AppRadius.smBr,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(
                            fontWeight: unread
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        relativeTimeLabel(
                          t.activity,
                          now,
                          l10n: AppLocalizations.of(context),
                        ),
                        style: text.labelSmall?.copyWith(
                          color: unread
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: unread ? AppColors.textPrimary : null,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          margin: const EdgeInsets.only(left: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AppRadius.pillBr,
                          ),
                          child: Text(
                            '${t.unread}',
                            style: text.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
