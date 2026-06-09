import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/moods.dart';
import '../../data/models/track.dart';
import '../../data/models/album.dart';
import '../../data/services/saavn_service.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/album_card.dart';

final _trendingProvider = FutureProvider<List<Track>>((ref) async {
  final quality = ref.read(qualityProvider).quality;
  final results = await Future.wait(
    trendingQueries.map((q) => SaavnService.searchSongs(q, limit: 12, quality: quality)),
  );
  final seen = <String>{};
  return results.expand((r) => r).where((t) => seen.add(t.id)).take(30).toList();
});

final _hotAlbumsProvider = FutureProvider<List<AlbumSummary>>((ref) async {
  return SaavnService.searchAlbums('trending albums', limit: 18);
});

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(_trendingProvider);
    final hotAlbumsAsync = ref.watch(_hotAlbumsProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final accent = ref.watch(themeProvider).accent;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).registerRoute('explore');
    });

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    const Text('EXPLORE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: AppColors.muted, letterSpacing: 2)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Discover',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(height: 4),
                const Text('Moods, genres and trending tracks — curated for you.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ),
        ),
        // Moods grid
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: const Text('Moods',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.0,
              ),
              itemCount: moods.length,
              itemBuilder: (ctx, i) {
                final mood = moods[i];
                return GestureDetector(
                  onTap: () => context.push('/search?q=${Uri.encodeComponent(mood.query)}'),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: mood.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(mood.label,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800,
                                  color: Colors.white, shadows: [
                                Shadow(color: Colors.black26, blurRadius: 4),
                              ])),
                        ),
                        Positioned(
                          bottom: -8,
                          right: -8,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Trending now
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
            child: const Text('Trending now',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ),
        trendingAsync.when(
          loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))),
          error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          data: (songs) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.5,
                ),
                itemCount: songs.take(8).length,
                itemBuilder: (ctx, i) {
                  final s = songs[i];
                  return GestureDetector(
                    onTap: () async {
                      final idx = songs.indexWhere((t) => t.id == s.id);
                      await playerNotifier.play(songs, startIndex: idx < 0 ? 0 : idx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                            child: s.cover != null && s.cover!.isNotEmpty
                                ? Image.network(s.cover!, width: 48, height: double.infinity, fit: BoxFit.cover)
                                : Container(width: 48, color: AppColors.secondary,
                                    child: const Icon(Icons.music_note, color: AppColors.muted)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                Text(s.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                              ],
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow, size: 14, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Hot albums
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
            child: const Text('Hot albums',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ),
        SliverToBoxAdapter(
          child: hotAlbumsAsync.when(
            loading: () => const SizedBox(height: 160),
            error: (_, __) => const SizedBox.shrink(),
            data: (albums) => SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: albums.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AlbumCard(album: albums[i], size: 140),
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
