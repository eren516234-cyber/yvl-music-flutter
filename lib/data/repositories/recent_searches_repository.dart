import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'yvl.recent.searches';

class RecentSearchesRepository {
  final SharedPreferences _prefs;

  RecentSearchesRepository(this._prefs);

  List<String> getAll() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(String term) async {
    final list = getAll();
    final next = [term, ...list.where((r) => r.toLowerCase() != term.toLowerCase())].take(8).toList();
    await _prefs.setString(_key, jsonEncode(next));
  }

  Future<void> remove(String term) async {
    final list = getAll().where((r) => r != term).toList();
    await _prefs.setString(_key, jsonEncode(list));
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
