import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The bottom-navigation shell: 4 tabs (Beranda / Solar Hub / Pesan / Profil),
/// each an independent navigation branch with its own state
/// (docs/ARCHITECTURE.md §7). Wraps a `StatefulNavigationShell` from GoRouter.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.solar_power_outlined),
      selectedIcon: Icon(Icons.solar_power),
      label: 'Solar Hub',
    ),
    NavigationDestination(
      icon: Icon(Icons.forum_outlined),
      selectedIcon: Icon(Icons.forum),
      label: 'Pesan',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
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
