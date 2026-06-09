import 'track.dart';

class Album {
  final String id;
  final String name;
  final String? year;
  final int? songCount;
  final String? cover;
  final String primaryArtist;
  final List<Track> songs;

  const Album({
    required this.id,
    required this.name,
    this.year,
    this.songCount,
    this.cover,
    required this.primaryArtist,
    this.songs = const [],
  });
}

class AlbumSummary {
  final String id;
  final String name;
  final String? cover;
  final String primaryArtist;
  final String? year;

  const AlbumSummary({
    required this.id,
    required this.name,
    this.cover,
    required this.primaryArtist,
    this.year,
  });
}
