import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/liked_track.dart';
import '../data/repositories/likes_repository.dart';

final likesRepoProvider = Provider<LikesRepository>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

class LikesNotifier extends StateNotifier<List<LikedTrack>> {
  final LikesRepository _repo;

  LikesNotifier(this._repo) : super(_repo.getAll());

  Future<void> toggle(LikedTrack track) async {
    await _repo.toggle(track);
    state = _repo.getAll();
  }

  bool isLiked(String id) => state.any((t) => t.id == id);
}

final likesProvider = StateNotifierProvider<LikesNotifier, List<LikedTrack>>((ref) {
  return LikesNotifier(ref.read(likesRepoProvider));
});
