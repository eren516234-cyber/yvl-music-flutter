import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/track.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/constants/colors.dart';

class SongRow extends ConsumerWidget {
  final Track song;
  final List<Track> queue;
  const SongRow({super.key, required this.song, required this.queue});

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: song.cover != null && song.cover!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: song.cover!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isCurrent ? accent : AppColors.foreground)),
                  const SizedBox(height: 2),
                  Text(song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
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
              ),
              child: const Icon(Icons.play_arrow, color: Colors.black, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 48,
        height: 48,
        color: AppColors.secondary,
        child: const Icon(Icons.music_note, color: AppColors.muted),
      );
}
