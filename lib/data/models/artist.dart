import 'track.dart';
import 'album.dart';

class Artist {
  final String id;
  final String name;
  final String? cover;
  final int? followerCount;
  final List<Track> topSongs;
  final List<AlbumSummary> topAlbums;

  const Artist({
    required this.id,
    required this.name,
    this.cover,
    this.followerCount,
    this.topSongs = const [],
    this.topAlbums = const [],
  });
}

class ArtistSummary {
  final String id;
  final String name;
  final String? cover;

  const ArtistSummary({
    required this.id,
    required this.name,
    this.cover,
  });
}
