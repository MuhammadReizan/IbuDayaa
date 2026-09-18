import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/components.dart';
import '../../../core/design/tokens.dart';
import '../../../core/format/format.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/selectors.dart';
import '../application/credit_score_provider.dart';

/// "Laporan Kredit Energi": the member's score and the record behind it, which
/// she can copy and hand to a lender she chooses. Copying asks for explicit
/// consent every time — nothing is sent anywhere by the app.
class CreditReportScreen extends ConsumerWidget {
  const CreditReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    if (me == null) return const Scaffold();
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final now = ref.read(clockProvider)();
    final engine = ref.read(creditScoringEngineProvider);
    final report = s.data.creditReportOf(me.id, now, engine);

    if (report == null) {
      return AppScaffold(
        title: l10n.creditReportTitle,
        onBack: () => context.pop(),
        scrollable: false,
        body: EmptyState(
          motif: BrandArtMotif.solar,
          title: l10n.creditReportTitle,
          message: l10n.creditReportEmpty,
        ),
      );
    }

    Future<void> copy() async {
      final ok = await confirmDialog(
        context,
        title: l10n.creditReportConsentTitle,
        message: l10n.creditReportConsentBody,
        confirmLabel: l10n.creditReportCopy,
      );
      if (!ok || !context.mounted) return;
      await Clipboard.setData(ClipboardData(text: report.toPlainText()));
      if (context.mounted) showAppSnack(context, l10n.creditReportCopied);
    }

    return AppScaffold(
      title: l10n.creditReportTitle,
      onBack: () => context.pop(),
      bottomBar: PrimaryButton(
        label: l10n.creditReportCopy,
        icon: Icons.copy_rounded,
        onPressed: copy,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(tone: InfoTone.info, message: l10n.creditReportIntro),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.memberName, style: text.titleMedium),
                Text(
                  '${report.businessName} · ${report.cooperativeName}',
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${report.score.score}/100',
                      style: text.headlineSmall,
                    ),
                    StatusPill(
                      label: report.score.band.localizedLabel(l10n),
                      tone: PillTone.info,
                    ),
                    if (report.loanReady)
                      StatusPill(
                        label: l10n.loanReadyBadge,
                        tone: PillTone.success,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (final f in report.score.factors)
                  KeyValueRow(
                    label: f.label,
                    value: '${f.points}/${f.maxPoints}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: l10n.creditReportMonths,
            child: Column(
              children: [
                for (final m in report.months)
                  KeyValueRow(
                    label: monthYearLabel(m.month, l10n: l10n),
                    value: formatKwh(m.kwh),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: l10n.creditReportActivity,
            child: Column(
              children: [
                KeyValueRow(
                  label: l10n.creditReportActivity,
                  value: l10n.creditReportSessions(
                    report.sessions8w,
                    formatKwh(report.kwh8w),
                  ),
                ),
                KeyValueRow(
                  label: l10n.creditReportAppliances,
                  value: '${report.appliances}',
                ),
                KeyValueRow(
                  label: l10n.creditReportQuota,
                  value: l10n.creditReportQuotaValue(
                    report.quotaGiven,
                    report.quotaReceived,
                  ),
                ),
                KeyValueRow(
                  label: l10n.creditReportDues,
                  value: '${report.duesConfirmed}',
                ),
                KeyValueRow(
                  label: l10n.creditReportInstallments,
                  value: report.installmentsDue == 0
                      ? l10n.creditReportInstallmentsNone
                      : l10n.creditReportInstallmentsValue(
                          report.installmentsOnTime,
                          report.installmentsDue,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            formatDateTime(report.generatedAt, l10n: l10n),
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
