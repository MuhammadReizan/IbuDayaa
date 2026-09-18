import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/ui_kit.dart';
import '../../core/l10n/l10n.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';

class MemberShell extends ConsumerWidget {
  const MemberShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(appStateProvider);
    final me = s.me;
    final unread = me == null ? 0 : s.data.unreadMessagesOf(me);
    return _Shell(
      shell: shell,
      flatBranchIndices: const [0, 4, 2, 3],
      centerBranchIndex: 1,
      centerItem: NavItem(
        icon: Icons.solar_power_outlined,
        activeIcon: Icons.solar_power_rounded,
        label: l10n.navSolarHub,
      ),
      items: [
        NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: l10n.navHome,
        ),
        NavItem(
          icon: Icons.bolt_outlined,
          activeIcon: Icons.bolt_rounded,
          label: l10n.navRecords,
        ),
        NavItem(
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
          label: l10n.navMessages,
          badge: unread,
        ),
        NavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: l10n.navProfile,
        ),
      ],
    );
  }
}

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(appStateProvider).data;
    final waiting = data.loansAwaitingAdmin.length;
    return _Shell(
      shell: shell,
      items: [
        NavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: l10n.navDashboard,
        ),
        NavItem(
          icon: Icons.request_page_outlined,
          activeIcon: Icons.request_page_rounded,
          label: l10n.navSubmissions,
          badge: waiting,
        ),
        NavItem(
          icon: Icons.groups_outlined,
          activeIcon: Icons.groups_rounded,
          label: l10n.navMembers,
        ),
        NavItem(
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
          label: l10n.navOther,
          badge: data.pendingPayments.length,
        ),
      ],
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.shell,
    required this.items,
    this.flatBranchIndices,
    this.centerItem,
    this.centerBranchIndex,
  });

  final StatefulNavigationShell shell;
  final List<NavItem> items;

  /// Router branch index for each entry in [items], in order. Defaults to
  /// the identity mapping (item `i` is branch `i`) when every branch is a
  /// flat tab, i.e. there is no [centerItem].
  final List<int>? flatBranchIndices;

  /// The item raised into the floating center button instead of the flat
  /// row (e.g. Solar Hub), and the branch it selects.
  final NavItem? centerItem;
  final int? centerBranchIndex;

  @override
  Widget build(BuildContext context) {
    final branchIndices =
        flatBranchIndices ?? List.generate(items.length, (i) => i);
    final selectedFlatIndex = branchIndices.indexOf(shell.currentIndex);
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppBottomNav(
        items: items,
        index: selectedFlatIndex,
        onTap: (i) => shell.goBranch(
          branchIndices[i],
          initialLocation: branchIndices[i] == shell.currentIndex,
        ),
        centerItem: centerItem,
        centerSelected:
            centerBranchIndex != null &&
            shell.currentIndex == centerBranchIndex,
        onCenterTap: centerBranchIndex == null
            ? null
            : () => shell.goBranch(
                centerBranchIndex!,
                initialLocation: centerBranchIndex == shell.currentIndex,
              ),
      ),
    );
  }
}
