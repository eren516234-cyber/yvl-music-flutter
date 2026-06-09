import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../data/models/album.dart';
import '../../data/services/saavn_service.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/song_row.dart';

final _albumDetailProvider = FutureProvider.family<Album, String>((ref, id) async {
  return SaavnService.getAlbum(id, quality: ref.read(qualityProvider).quality);
});

class AlbumScreen extends ConsumerWidget {
  final String id;
  const AlbumScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(_albumDetailProvider(id));
    final playerNotifier = ref.read(playerProvider.notifier);
    final accent = ref.watch(themeProvider).accent;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).registerRoute('album');
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: albumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("Couldn't load album.",
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            TextButton(onPressed: () => context.pop(), child: const Text('Back')),
          ]),
        ),
        data: (album) => CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              ),
              pinned: true,
              title: Text(album.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: album.cover != null && album.cover!.isNotEmpty
                          ? Image.network(album.cover!, width: 240, height: 240, fit: BoxFit.cover)
                          : Container(
                              width: 240, height: 240, color: AppColors.secondary,
                              child: const Icon(Icons.album, size: 80, color: AppColors.muted)),
                    ),
                    const SizedBox(height: 16),
                    Text(album.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        album.primaryArtist,
                        if (album.year != null) album.year!,
                        if (album.songCount != null) '${album.songCount} songs',
                      ].join(' • '),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              if (album.songs.isEmpty) return;
                              await playerNotifier.play(album.songs);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow,
                                      color: accent.computeLuminance() > 0.4
                                          ? Colors.black
                                          : Colors.white,
                                      size: 18),
                                  const SizedBox(width: 6),
                                  Text('Play',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: accent.computeLuminance() > 0.4
                                              ? Colors.black
                                              : Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              if (album.songs.isEmpty) return;
                              final shuffled = [...album.songs]..shuffle();
                              await playerNotifier.play(shuffled);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shuffle, size: 18),
                                  SizedBox(width: 6),
                                  Text('Shuffle',
                                      style: TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SongRow(song: album.songs[i], queue: album.songs),
                ),
                childCount: album.songs.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
