import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/liked_track.dart';

const _key = 'yvl.likes.v2';

class LikesRepository {
  final SharedPreferences _prefs;

  LikesRepository(this._prefs);

  List<LikedTrack> getAll() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => LikedTrack.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<LikedTrack> tracks) async {
    await _prefs.setString(_key, jsonEncode(tracks.map((t) => t.toJson()).toList()));
  }

  Future<bool> toggle(LikedTrack track) async {
    final list = getAll();
    final exists = list.any((t) => t.id == track.id);
    if (exists) {
      final next = list.where((t) => t.id != track.id).toList();
      await save(next);
      return false;
    } else {
      final next = [track, ...list];
      await save(next);
      return true;
    }
  }

  bool isLiked(String id) => getAll().any((t) => t.id == id);
}
