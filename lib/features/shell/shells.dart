import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/ui_kit.dart';
import '../../core/state/app_state.dart';
import '../../core/state/selectors.dart';

class MemberShell extends ConsumerWidget {
  const MemberShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final me = s.me;
    final unread = me == null ? 0 : s.data.unreadMessagesOf(me);
    return _Shell(
      shell: shell,
      items: [
        const NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Beranda',
        ),
        const NavItem(
          icon: Icons.solar_power_outlined,
          activeIcon: Icons.solar_power_rounded,
          label: 'Solar Hub',
        ),
        NavItem(
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
          label: 'Pesan',
          badge: unread,
        ),
        const NavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profil',
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
    final data = ref.watch(appStateProvider).data;
    final waiting = data.loansAwaitingAdmin.length;
    return _Shell(
      shell: shell,
      items: [
        const NavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: 'Dasbor',
        ),
        NavItem(
          icon: Icons.request_page_outlined,
          activeIcon: Icons.request_page_rounded,
          label: 'Pengajuan',
          badge: waiting,
        ),
        const NavItem(
          icon: Icons.groups_outlined,
          activeIcon: Icons.groups_rounded,
          label: 'Anggota',
        ),
        NavItem(
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
          label: 'Lainnya',
          badge: data.pendingPayments.length,
        ),
      ],
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.shell, required this.items});

  final StatefulNavigationShell shell;
  final List<NavItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppBottomNav(
        items: items,
        index: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
