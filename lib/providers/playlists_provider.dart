import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/playlist.dart';
import '../data/repositories/playlists_repository.dart';

final playlistsRepoProvider = Provider<PlaylistsRepository>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

class PlaylistsNotifier extends StateNotifier<List<Playlist>> {
  final PlaylistsRepository _repo;

  PlaylistsNotifier(this._repo) : super(_repo.getAll());

  void _refresh() => state = _repo.getAll();

  Future<Playlist> create(String name) async {
    final pl = await _repo.create(name);
    _refresh();
    return pl;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _refresh();
  }

  Future<void> rename(String id, String name) async {
    await _repo.rename(id, name);
    _refresh();
  }

  Future<void> addTrack(String playlistId, PlaylistTrack track) async {
    await _repo.addTrack(playlistId, track);
    _refresh();
  }

  Future<void> removeTrack(String playlistId, String trackId) async {
    await _repo.removeTrack(playlistId, trackId);
    _refresh();
  }

  Future<void> addToDownloads(PlaylistTrack track) async {
    await _repo.ensureDownloads();
    await _repo.addTrack(downloadsPlaylistId, track);
    _refresh();
  }
}

final playlistsProvider = StateNotifierProvider<PlaylistsNotifier, List<Playlist>>((ref) {
  return PlaylistsNotifier(ref.read(playlistsRepoProvider));
});
