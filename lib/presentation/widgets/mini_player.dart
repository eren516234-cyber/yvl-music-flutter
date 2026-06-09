import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/constants/colors.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final accent = ref.watch(themeProvider).accent;
    final track = state.current;
    if (track == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => notifier.expand(true),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: track.cover != null && track.cover!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: track.cover!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _placeholder(44),
                          )
                        : _placeholder(44),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async => await notifier.prev(),
                    icon: const Icon(Icons.skip_previous, size: 22),
                    color: AppColors.foreground,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  GestureDetector(
                    onTap: notifier.toggle,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        state.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.background,
                        size: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async => await notifier.next(),
                    icon: const Icon(Icons.skip_next, size: 22),
                    color: AppColors.foreground,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            if (state.duration > 0)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16)),
                child: LinearProgressIndicator(
                  value: state.position / state.duration,
                  backgroundColor: AppColors.secondary,
                  valueColor: AlwaysStoppedAnimation(accent),
                  minHeight: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        color: AppColors.secondary,
        child: const Icon(Icons.music_note, color: AppColors.muted, size: 20),
      );
}
