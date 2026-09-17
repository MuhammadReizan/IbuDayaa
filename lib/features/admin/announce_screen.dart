import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/format/format.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';
import '../../core/state/actions.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';

class AnnounceScreen extends ConsumerStatefulWidget {
  const AnnounceScreen({super.key});

  @override
  ConsumerState<AnnounceScreen> createState() => _AnnounceScreenState();
}

class _AnnounceScreenState extends ConsumerState<AnnounceScreen> {
  final _body = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStateProvider).data;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final thread = data.threads
        .where((t) => t.kind == ThreadKind.announcement)
        .firstOrNull;
    final past = thread == null
        ? const <Message>[]
        : data
              .messagesOf(thread.id)
              .reversed
              .where((m) => !m.isSystem)
              .toList();

    return AppScaffold(
      title: l10n.scaffoldAdminAnnounce,
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: l10n.adminAnnounceSendCount(data.memberProfiles.length),
        icon: Icons.campaign_rounded,
        loading: _busy,
        onPressed: thread == null || _body.text.trim().isEmpty
            ? null
            : () async {
                final ok = await confirmDialog(
                  context,
                  title: l10n.adminAnnounceConfirmTitle,
                  message: l10n.adminAnnounceConfirmMessage,
                  confirmLabel: l10n.adminAnnounceConfirmSend,
                );
                if (!ok || !context.mounted) return;
                setState(() => _busy = true);
                final sent = await runAction(
                  context,
                  () => ref
                      .read(actionsProvider)
                      .sendMessage(thread.id, _body.text.trim()),
                  success: l10n.adminAnnounceSent,
                );
                if (!mounted) return;
                setState(() => _busy = false);
                if (sent) _body.clear();
              },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: l10n.adminAnnounceMessage,
            controller: _body,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            hint: l10n.adminAnnounceHint,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.adminAnnounceHelper, style: text.bodySmall),
          if (past.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: l10n.adminAnnouncePreviousSection),
            for (final m in past.take(10))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SectionCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.body, style: text.bodyMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${data.nameOf(m.senderId)} · ${formatDateTime(m.createdAt)}',
                        style: text.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
