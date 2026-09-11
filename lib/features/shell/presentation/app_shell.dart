import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The bottom-navigation shell: Beranda / Solar Hub / Arisan / Profil, each an
/// independent navigation branch with its own state.
///
/// There is deliberately no "Pesan" tab: this build has no server, so a chat
/// would be a button that cannot work. Arisan takes that slot instead — it is
/// a core pillar and people open it often.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.solar_power_outlined),
      selectedIcon: Icon(Icons.solar_power_rounded),
      label: 'Solar Hub',
    ),
    NavigationDestination(
      icon: Icon(Icons.groups_2_outlined),
      selectedIcon: Icon(Icons.groups_2_rounded),
      label: 'Arisan',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    ),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab again pops it to its root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: _destinations,
      ),
    );
  }
}
