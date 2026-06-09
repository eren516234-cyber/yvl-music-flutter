import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/recent_searches_repository.dart';

final recentSearchesRepoProvider = Provider<RecentSearchesRepository>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  final RecentSearchesRepository _repo;

  RecentSearchesNotifier(this._repo) : super(_repo.getAll());

  Future<void> add(String term) async {
    await _repo.add(term);
    state = _repo.getAll();
  }

  Future<void> remove(String term) async {
    await _repo.remove(term);
    state = _repo.getAll();
  }
}

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier(ref.read(recentSearchesRepoProvider));
});
