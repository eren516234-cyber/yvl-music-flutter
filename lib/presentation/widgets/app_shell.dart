import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'mini_player.dart';
import 'full_player.dart';
import '../../providers/player_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static int _tabIndex(String location) {
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/search')) return 2;
    if (location.startsWith('/library')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final location = GoRouterState.of(context).uri.toString();
    final idx = _tabIndex(location);

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [
          child,
          if (playerState.expanded) const FullPlayer(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (playerState.current != null && !playerState.expanded)
            const MiniPlayer(),
          NavigationBar(
            selectedIndex: idx,
            onDestinationSelected: (i) {
              final routes = ['/', '/explore', '/search', '/library', '/settings'];
              context.go(routes[i]);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
