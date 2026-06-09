import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/settings_provider.dart';
import 'providers/likes_provider.dart';
import 'providers/playlists_provider.dart';
import 'providers/recent_searches_provider.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/likes_repository.dart';
import 'data/repositories/playlists_repository.dart';
import 'data/repositories/recent_searches_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        settingsRepoProvider.overrideWithValue(SettingsRepository(prefs)),
        likesRepoProvider.overrideWithValue(LikesRepository(prefs)),
        playlistsRepoProvider.overrideWithValue(PlaylistsRepository(prefs)),
        recentSearchesRepoProvider
            .overrideWithValue(RecentSearchesRepository(prefs)),
      ],
      child: const YvlApp(),
    ),
  );
}
