import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';

const _key = 'yvl.playlists';

class PlaylistsRepository {
  final SharedPreferences _prefs;

  PlaylistsRepository(this._prefs);

  List<Playlist> getAll() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => Playlist.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<Playlist> pls) async {
    await _prefs.setString(_key, jsonEncode(pls.map((p) => p.toJson()).toList()));
  }

  Future<Playlist> create(String name) async {
    final pls = getAll();
    final rand = Random().nextInt(99999).toString().padLeft(5, '0');
    final pl = Playlist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}_$rand',
      name: name.trim().isEmpty ? 'Untitled playlist' : name.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    pls.insert(0, pl);
    await _save(pls);
    return pl;
  }

  Future<void> delete(String id) async {
    final pls = getAll().where((p) => p.id != id).toList();
    await _save(pls);
  }

  Future<void> rename(String id, String name) async {
    final pls = getAll();
    final idx = pls.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    pls[idx] = pls[idx].copyWith(name: name.trim().isEmpty ? pls[idx].name : name.trim());
    await _save(pls);
  }

  Future<void> addTrack(String playlistId, PlaylistTrack track) async {
    final pls = getAll();
    final idx = pls.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return;
    if (pls[idx].tracks.any((t) => t.id == track.id)) return;
    final tracks = [...pls[idx].tracks, track];
    pls[idx] = pls[idx].copyWith(tracks: tracks);
    await _save(pls);
  }

  Future<void> removeTrack(String playlistId, String trackId) async {
    final pls = getAll();
    final idx = pls.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return;
    final tracks = pls[idx].tracks.where((t) => t.id != trackId).toList();
    pls[idx] = pls[idx].copyWith(tracks: tracks);
    await _save(pls);
  }

  Future<Playlist> ensureDownloads() async {
    final pls = getAll();
    final existing = pls.firstWhere(
      (p) => p.id == downloadsPlaylistId,
      orElse: () => Playlist(id: '', name: '', createdAt: 0),
    );
    if (existing.id.isNotEmpty) return existing;
    final pl = Playlist(
      id: downloadsPlaylistId,
      name: 'Downloads',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    pls.insert(0, pl);
    await _save(pls);
    return pl;
  }
}
