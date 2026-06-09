import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'presentation/widgets/app_shell.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/explore_screen.dart';
import 'presentation/screens/search_screen.dart';
import 'presentation/screens/library_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/album_screen.dart';
import 'presentation/screens/artist_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) {
            final q = state.uri.queryParameters['q'] ?? '';
            return SearchScreen(initialQuery: q);
          },
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/album/:id',
      builder: (context, state) =>
          AlbumScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/artist/:id',
      builder: (context, state) =>
          ArtistScreen(id: state.pathParameters['id']!),
    ),
  ],
);

class YvlApp extends ConsumerWidget {
  const YvlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(themeProvider).accent;
    return MaterialApp.router(
      title: 'YVL',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(accent),
      routerConfig: _router,
    );
  }
}
