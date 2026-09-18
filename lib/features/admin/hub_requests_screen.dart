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

/// Where an admin verifies "member A wants to use the hub now". A request
/// appears here as soon as a member scans the hub QR; approving it books the
/// session, and confirming it afterwards (Pengaturan Hub) records the usage.
class HubRequestsScreen extends ConsumerWidget {
  const HubRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStateProvider).data;
    final l10n = AppLocalizations.of(context);
    final requests = data.hubRequests;

    Future<void> respond(HubBooking b, {required bool approve}) => runAction(
      context,
      () => ref
          .read(actionsProvider)
          .respondToConnectionRequest(b.id, approve: approve),
      success: approve
          ? l10n.hubConnectionApprovedToast
          : l10n.hubConnectionRejectedToast,
    );

    return AppScaffold(
      title: l10n.adminRequestsTitle,
      onBack: () => context.pop(),
      scrollable: requests.isNotEmpty,
      body: requests.isEmpty
          ? EmptyState(
              motif: BrandArtMotif.solar,
              title: l10n.adminRequestsEmpty,
              message: l10n.adminRequestsIntro,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoBanner(
                  tone: InfoTone.info,
                  message: l10n.adminRequestsIntro,
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final b in requests) ...[
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TintedRow(
                          icon: Icons.qr_code_scanner_rounded,
                          tone: PillTone.warning,
                          title: data.nameOf(b.userId),
                          subtitle:
                              '${b.applianceName} · ${formatKwh(b.estKwh)} · '
                              '${data.slot(b.slotId)?.label ?? ''}',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                label: l10n.hubConnectionReject,
                                onPressed: () => respond(b, approve: false),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: PrimaryButton(
                                label: l10n.hubConnectionApprove,
                                onPressed: () => respond(b, approve: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}
