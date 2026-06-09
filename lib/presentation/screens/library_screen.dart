import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../data/models/liked_track.dart';
import '../../data/models/playlist.dart';
import '../../data/models/track.dart';
import '../../data/services/saavn_service.dart';
import '../../providers/likes_provider.dart';
import '../../providers/playlists_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final liked = ref.watch(likesProvider);
    final accent = ref.watch(themeProvider).accent;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).registerRoute('library');
    });

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            child: const Text('Library',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
          ),
        ),
        // Playlists section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Playlists', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text('${playlists.length}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
        ),
        if (playlists.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _EmptyCard(
                text: 'Tap + on any playing track to start a playlist. Downloads land here too.',
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: _PlaylistCard(playlist: playlists[i]),
              ),
              childCount: playlists.length,
            ),
          ),
        // Liked section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, size: 18, color: accent),
                    const SizedBox(width: 8),
                    const Text('Liked', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
                if (liked.isNotEmpty)
                  Row(
                    children: [
                      _SmallBtn(label: 'Shuffle', icon: Icons.shuffle,
                          onTap: () => _playLiked(ref, liked, shuffle: true)),
                      const SizedBox(width: 8),
                      _SmallBtn(label: 'Play all', icon: Icons.play_arrow, accent: accent,
                          onTap: () => _playLiked(ref, liked)),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (liked.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _EmptyCard(text: 'Tap the heart on any track to save it here.'),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _LikedRow(track: liked[i], onPlay: () => _playLiked(ref, liked, startIndex: i)),
              ),
              childCount: liked.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Future<void> _playLiked(WidgetRef ref, List<LikedTrack> liked,
      {bool shuffle = false, int startIndex = 0}) async {
    final quality = ref.read(qualityProvider).quality;
    final tracks = await Future.wait(liked.map((t) async {
      try {
        return await SaavnService.getSong(t.id, quality: quality);
      } catch (_) {
        return Track(id: t.id, title: t.title, artist: t.artist, cover: t.cover, duration: 0);
      }
    }));
    var list = tracks.toList();
    var start = startIndex;
    if (shuffle) { list.shuffle(); start = 0; }
    await ref.read(playerProvider.notifier).play(list, startIndex: start);
  }
}

class _PlaylistCard extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(themeProvider).accent;
    final notifier = ref.read(playlistsProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: playlist.id == downloadsPlaylistId ? accent : AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    playlist.id == downloadsPlaylistId ? Icons.download : Icons.queue_music,
                    color: AppColors.foreground,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(playlist.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('${playlist.tracks.length} tracks',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                ),
                GestureDetector(
                  onTap: () => _playShuffle(ref, playlist),
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                    child: const Icon(Icons.shuffle, size: 16),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _playAll(ref, playlist),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow, size: 20, color: Colors.black),
                  ),
                ),
                if (playlist.id != downloadsPlaylistId) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDelete(context, notifier, playlist),
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                      child: const Icon(Icons.delete_outline, size: 16, color: AppColors.muted),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (playlist.tracks.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            ...playlist.tracks.take(4).toList().asMap().entries.map((e) {
              final t = e.value;
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: t.cover != null && t.cover!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: t.cover!, width: 36, height: 36, fit: BoxFit.cover)
                      : Container(width: 36, height: 36, color: AppColors.secondary,
                          child: const Icon(Icons.music_note, size: 16, color: AppColors.muted)),
                ),
                title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                subtitle: Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                trailing: const Icon(Icons.play_arrow, size: 16, color: AppColors.muted),
                onTap: () => _playAt(ref, playlist, e.key),
              );
            }),
            if (playlist.tracks.length > 4)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text('+${playlist.tracks.length - 4} more',
                    style: const TextStyle(color: AppColors.muted, fontSize: 10)),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _playAll(WidgetRef ref, Playlist pl, {int start = 0}) async {
    if (pl.tracks.isEmpty) return;
    final quality = ref.read(qualityProvider).quality;
    final tracks = await Future.wait(pl.tracks.map((t) async {
      try { return await SaavnService.getSong(t.id, quality: quality); }
      catch (_) { return Track(id: t.id, title: t.title, artist: t.artist, cover: t.cover, duration: 0); }
    }));
    await ref.read(playerProvider.notifier).play(tracks.toList(), startIndex: start);
  }

  Future<void> _playShuffle(WidgetRef ref, Playlist pl) async {
    if (pl.tracks.isEmpty) return;
    final quality = ref.read(qualityProvider).quality;
    final tracks = await Future.wait(pl.tracks.map((t) async {
      try { return await SaavnService.getSong(t.id, quality: quality); }
      catch (_) { return Track(id: t.id, title: t.title, artist: t.artist, cover: t.cover, duration: 0); }
    }));
    final shuffled = tracks.toList()..shuffle();
    await ref.read(playerProvider.notifier).play(shuffled);
  }

  Future<void> _playAt(WidgetRef ref, Playlist pl, int index) => _playAll(ref, pl, start: index);

  void _confirmDelete(BuildContext ctx, PlaylistsNotifier notifier, Playlist pl) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete playlist'),
        content: Text('Delete "${pl.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); notifier.delete(pl.id); },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _LikedRow extends ConsumerWidget {
  final LikedTrack track;
  final VoidCallback onPlay;
  const _LikedRow({required this.track, required this.onPlay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(themeProvider).accent;
    final notifier = ref.read(likesProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPlay,
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: track.cover != null && track.cover!.isNotEmpty
                    ? CachedNetworkImage(imageUrl: track.cover!, width: 48, height: 48, fit: BoxFit.cover)
                    : Container(width: 48, height: 48, color: AppColors.secondary,
                        child: const Icon(Icons.music_note, color: AppColors.muted)),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onPlay,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: Colors.black, size: 18),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => notifier.toggle(track),
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
              child: Icon(Icons.favorite, color: accent, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accent;
  const _SmallBtn({required this.label, required this.icon, required this.onTap, this.accent});

  @override
  Widget build(BuildContext context) {
    final bg = accent ?? AppColors.secondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: accent != null ? Colors.black : AppColors.foreground),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: accent != null ? Colors.black : AppColors.foreground)),
          ],
        ),
      ),
    );
  }
}
