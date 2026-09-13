import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/row.dart';
import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';

class ThreadScreen extends ConsumerStatefulWidget {
  const ThreadScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    if (!mounted) return;
    final s = ref.read(appStateProvider);
    final me = s.me;
    final thread = s.data.thread(widget.threadId);
    if (me == null || thread == null) return;
    if (s.data.summarize(thread, me).unread == 0) return;
    try {
      await ref.read(actionsProvider).markThreadRead(widget.threadId);
    } catch (_) {}
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await runAction(
      context,
      () => ref.read(actionsProvider).sendMessage(widget.threadId, body),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _input.clear();
      await _markRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final data = s.data;
    final thread = data.thread(widget.threadId);
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    if (thread == null) {
      return AppScaffold(
        title: l10n.scaffoldMessages,
        onBack: () => context.pop(),
        scrollable: false,
        body: const EmptyState(title: 'Percakapan tidak ditemukan'),
      );
    }

    final summary = data.summarize(thread, me);
    final messages = data.messagesOf(thread.id).reversed.toList();
    final readOnly = thread.kind == ThreadKind.announcement && !me.isAdmin;
    final participants = data.participants
        .where((p) => p.threadId == thread.id)
        .length;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(summary.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(switch (thread.kind) {
              ThreadKind.announcement => 'Pengumuman koperasi',
              ThreadKind.group => '$participants peserta',
              ThreadKind.support => me.isAdmin ? 'Anggota' : 'Admin koperasi',
              ThreadKind.direct => 'Anggota koperasi',
            }, style: text.labelSmall),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada pesan. Mulai percakapan.',
                        style: text.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final m = messages[i];
                        final older = i + 1 < messages.length
                            ? messages[i + 1]
                            : null;
                        final newDay =
                            older == null ||
                            !sameDay(older.createdAt, m.createdAt);
                        final showName =
                            thread.kind == ThreadKind.group ||
                            thread.kind == ThreadKind.support && !me.isAdmin;
                        return Column(
                          children: [
                            if (newDay)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                child: Text(
                                  formatLongDate(m.createdAt),
                                  style: text.labelSmall,
                                ),
                              ),
                            ChatBubble(
                              body: m.body,
                              time: formatClock(m.createdAt),
                              mine: m.senderId == me.id,
                              system: m.isSystem,
                              senderName: showName
                                  ? data.nameOf(m.senderId)
                                  : null,
                            ),
                          ],
                        );
                      },
                    ),
            ),
            if (readOnly)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: AppColors.surfaceAlt,
                child: Text(
                  'Hanya admin yang bisa mengirim pengumuman.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.outlineSubtle),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan…',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      tooltip: 'Kirim',
                      style: IconButton.styleFrom(
                        minimumSize: const Size(kMinTapTarget, kMinTapTarget),
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: _input.text.trim().isEmpty || _sending
                          ? null
                          : _send,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
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
