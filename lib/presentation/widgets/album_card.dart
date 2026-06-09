import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/album.dart';
import '../../core/constants/colors.dart';

class AlbumCard extends ConsumerWidget {
  final AlbumSummary album;
  final double size;
  const AlbumCard({super.key, required this.album, this.size = 160});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/album/${album.id}'),
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: album.cover != null && album.cover!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: album.cover!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(height: 6),
            Text(album.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(album.primaryArtist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: size,
        height: size,
        color: AppColors.secondary,
        child: const Icon(Icons.album, color: AppColors.muted, size: 40),
      );
}
