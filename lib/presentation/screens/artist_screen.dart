import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../data/models/artist.dart';
import '../../data/services/saavn_service.dart';
import '../../providers/settings_provider.dart';
import '../widgets/song_row.dart';
import '../widgets/album_card.dart';

final _artistDetailProvider = FutureProvider.family<Artist, String>((ref, id) async {
  return SaavnService.getArtist(id, quality: ref.read(qualityProvider).quality);
});

class ArtistScreen extends ConsumerWidget {
  final String id;
  const ArtistScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(_artistDetailProvider(id));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).registerRoute('artist');
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: artistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("Couldn't load artist.",
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            TextButton(onPressed: () => context.pop(), child: const Text('Back')),
          ]),
        ),
        data: (artist) => CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              ),
              pinned: true,
              expandedHeight: 280,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (artist.cover != null && artist.cover!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: artist.cover!,
                        fit: BoxFit.cover,
                        color: Colors.black.withOpacity(0.4),
                        colorBlendMode: BlendMode.darken,
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.background],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(artist.name,
                              style: const TextStyle(
                                  fontSize: 36, fontWeight: FontWeight.w900)),
                          if (artist.followerCount != null)
                            Text(
                                '${_formatCount(artist.followerCount!)} followers',
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (artist.topSongs.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text('Top songs',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SongRow(
                        song: artist.topSongs[i], queue: artist.topSongs),
                  ),
                  childCount: artist.topSongs.take(10).length,
                ),
              ),
            ],
            if (artist.topAlbums.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text('Albums',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: artist.topAlbums.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: AlbumCard(album: artist.topAlbums[i], size: 150),
                    ),
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
