import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/settings_repository.dart';
import '../core/constants/colors.dart';

final settingsRepoProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

class ThemeState {
  final bool rainbow;
  final bool aurora;
  final bool paint;
  final bool perScreen;
  final String baseAccent;
  final String currentRoute;

  const ThemeState({
    this.rainbow = false,
    this.aurora = false,
    this.paint = false,
    this.perScreen = false,
    this.baseAccent = '#ffffff',
    this.currentRoute = 'home',
  });

  Color get accent {
    if (perScreen) {
      return perScreenColors[currentRoute] ?? AppColors.defaultAccent;
    }
    if (paint || rainbow) return hexToColor(baseAccent);
    return AppColors.defaultAccent;
  }

  ThemeState copyWith({
    bool? rainbow,
    bool? aurora,
    bool? paint,
    bool? perScreen,
    String? baseAccent,
    String? currentRoute,
  }) =>
      ThemeState(
        rainbow: rainbow ?? this.rainbow,
        aurora: aurora ?? this.aurora,
        paint: paint ?? this.paint,
        perScreen: perScreen ?? this.perScreen,
        baseAccent: baseAccent ?? this.baseAccent,
        currentRoute: currentRoute ?? this.currentRoute,
      );
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  final SettingsRepository _repo;

  ThemeNotifier(this._repo)
      : super(ThemeState(
          rainbow: _repo.rainbow,
          aurora: _repo.aurora,
          paint: _repo.paint,
          perScreen: _repo.perScreen,
          baseAccent: _repo.baseAccent,
        ));

  void setRainbow(bool v) {
    state = state.copyWith(rainbow: v);
    _repo.setRainbow(v);
  }

  void setAurora(bool v) {
    state = state.copyWith(aurora: v);
    _repo.setAurora(v);
  }

  void setPaint(bool v) {
    state = state.copyWith(paint: v);
    _repo.setPaint(v);
  }

  void setPerScreen(bool v) {
    state = state.copyWith(perScreen: v);
    _repo.setPerScreen(v);
  }

  void setBaseAccent(String hex) {
    state = state.copyWith(baseAccent: hex, paint: true, rainbow: false);
    _repo.setBaseAccent(hex);
    _repo.setPaint(true);
    _repo.setRainbow(false);
  }

  void registerRoute(String route) {
    state = state.copyWith(currentRoute: route);
  }

  void reset() {
    state = const ThemeState();
    _repo.resetTheme();
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier(ref.read(settingsRepoProvider));
});

class QualityState {
  final String quality;
  const QualityState({this.quality = '320kbps'});
}

class QualityNotifier extends StateNotifier<QualityState> {
  final SettingsRepository _repo;

  QualityNotifier(this._repo) : super(QualityState(quality: _repo.quality));

  void setQuality(String q) {
    state = QualityState(quality: q);
    _repo.setQuality(q);
  }
}

final qualityProvider = StateNotifierProvider<QualityNotifier, QualityState>((ref) {
  return QualityNotifier(ref.read(settingsRepoProvider));
});
