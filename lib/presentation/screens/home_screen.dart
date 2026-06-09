import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/moods.dart';
import '../../data/models/album.dart';
import '../../data/models/track.dart';
import '../../data/services/saavn_service.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/album_card.dart';

final _songsProvider = FutureProvider.family<List<Track>, String>((ref, query) async {
  return SaavnService.searchSongs(query, limit: 30, quality: ref.read(qualityProvider).quality);
});

final _albumsProvider = FutureProvider.family<List<AlbumSummary>, String>((ref, query) async {
  return SaavnService.searchAlbums(query, limit: 24);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).registerRoute('home');
    });
  }

  @override
  Widget build(BuildContext context) {
    final tab = homeTabs[_tabIndex];
    final songsAsync = ref.watch(_songsProvider(tab.query));
    final albumsAsync = ref.watch(_albumsProvider(tab.query));
    final accent = ref.watch(themeProvider).accent;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('YVL',
                    style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, height: 1)),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Center(
                    child: Text('E',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: accent.computeLuminance() > 0.4 ? Colors.black : Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              itemCount: homeTabs.length,
              itemBuilder: (ctx, i) {
                final selected = i == _tabIndex;
                return GestureDetector(
                  onTap: () => setState(() => _tabIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.foreground : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(homeTabs[i].label,
                        style: TextStyle(
                            color: selected ? AppColors.background : AppColors.muted,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13)),
                  ),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: const Text('Quick picks',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ),
        songsAsync.when(
          loading: () => SliverToBoxAdapter(child: _skeletonRows()),
          error: (_, __) => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text("Couldn't load songs.", style: TextStyle(color: AppColors.muted)),
            ),
          ),
          data: (songs) {
            final quick = songs.take(8).toList();
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _FeaturedRow(song: quick[i], queue: songs),
                ),
                childCount: quick.length,
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
            child: const Text('New drops',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ),
        SliverToBoxAdapter(
          child: albumsAsync.when(
            loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (albums) => SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: albums.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AlbumCard(album: albums[i], size: 160),
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _skeletonRows() {
    return Column(
      children: List.generate(5, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          children: [
            Container(width: 48, height: 48, color: AppColors.secondary,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.secondary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 12, width: 140, color: AppColors.secondary,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: AppColors.secondary)),
                const SizedBox(height: 6),
                Container(height: 10, width: 90, color: AppColors.secondary,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: AppColors.secondary)),
              ]),
            ),
          ],
        ),
      )),
    );
  }
}

class _FeaturedRow extends ConsumerWidget {
  final Track song;
  final List<Track> queue;
  const _FeaturedRow({required this.song, required this.queue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final accent = ref.watch(themeProvider).accent;
    final isCurrent = playerState.current?.id == song.id;

    return GestureDetector(
      onTap: () async {
        final idx = queue.indexWhere((t) => t.id == song.id);
        await playerNotifier.play(queue, startIndex: idx < 0 ? 0 : idx);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: song.cover != null && song.cover!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: song.cover!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                          width: 52, height: 52, color: AppColors.secondary,
                          child: const Icon(Icons.music_note, color: AppColors.muted)),
                    )
                  : Container(width: 52, height: 52, color: AppColors.secondary,
                      child: const Icon(Icons.music_note, color: AppColors.muted)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(song.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(song.artist,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 8),
            Text(formatDuration(song.duration),
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 8)],
              ),
              child: Icon(Icons.play_arrow,
                  color: accent.computeLuminance() > 0.4 ? Colors.black : Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
