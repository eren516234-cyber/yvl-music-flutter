import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  String get quality => _prefs.getString('yvl.quality') ?? '320kbps';
  Future<void> setQuality(String q) => _prefs.setString('yvl.quality', q);

  bool get rainbow => _prefs.getBool('yvl.theme.rainbow') ?? false;
  bool get aurora => _prefs.getBool('yvl.theme.aurora') ?? false;
  bool get paint => _prefs.getBool('yvl.theme.paint') ?? false;
  bool get perScreen => _prefs.getBool('yvl.theme.perScreen') ?? false;
  String get baseAccent => _prefs.getString('yvl.theme.baseAccent') ?? '#ffffff';

  Future<void> setRainbow(bool v) => _prefs.setBool('yvl.theme.rainbow', v);
  Future<void> setAurora(bool v) => _prefs.setBool('yvl.theme.aurora', v);
  Future<void> setPaint(bool v) => _prefs.setBool('yvl.theme.paint', v);
  Future<void> setPerScreen(bool v) => _prefs.setBool('yvl.theme.perScreen', v);
  Future<void> setBaseAccent(String hex) => _prefs.setString('yvl.theme.baseAccent', hex);

  Future<void> resetTheme() async {
    await _prefs.setBool('yvl.theme.rainbow', false);
    await _prefs.setBool('yvl.theme.aurora', false);
    await _prefs.setBool('yvl.theme.paint', false);
    await _prefs.setBool('yvl.theme.perScreen', false);
    await _prefs.setString('yvl.theme.baseAccent', '#ffffff');
  }
}
