import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/components.dart';
import '../../core/design/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state.dart';
import 'admin_home_screen.dart';

enum _Filter { waiting, running, done, all }

class AdminLoansScreen extends ConsumerStatefulWidget {
  const AdminLoansScreen({super.key});

  @override
  ConsumerState<AdminLoansScreen> createState() => _AdminLoansScreenState();
}

class _AdminLoansScreenState extends ConsumerState<AdminLoansScreen> {
  _Filter _filter = _Filter.waiting;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStateProvider).data;
    final l10n = AppLocalizations.of(context);
    final all = [...data.loans]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    bool match(LoanApplication l) => switch (_filter) {
      _Filter.waiting =>
        l.status == LoanStatus.submitted ||
            l.status == LoanStatus.inReview ||
            l.status == LoanStatus.approved,
      _Filter.running => l.status == LoanStatus.disbursed,
      _Filter.done => l.status.isFinal,
      _Filter.all => true,
    };
    final list = all.where(match).toList();
    int count(_Filter f) {
      final prev = _filter;
      _filter = f;
      final n = all.where(match).length;
      _filter = prev;
      return n;
    }

    return AppScaffold(
      title: l10n.scaffoldAdminLoans,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (f, label) in [
                  (_Filter.waiting, l10n.labelPending),
                  (_Filter.running, l10n.labelActive),
                  (_Filter.done, l10n.labelCompleted),
                  (_Filter.all, l10n.actionViewAll),
                ]) ...[
                  ChoiceChip(
                    label: Text('$label (${count(f)})'),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: EmptyState(
                motif: BrandArtMotif.finance,
                title: l10n.adminLoansEmpty,
              ),
            )
          else
            for (final l in list) ...[
              AdminLoanRow(loan: l, name: data.nameOf(l.userId)),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}
