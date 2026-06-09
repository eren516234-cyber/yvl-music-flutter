class PlaylistTrack {
  final String id;
  final String title;
  final String artist;
  final String? cover;

  const PlaylistTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.cover,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'cover': cover,
      };

  factory PlaylistTrack.fromJson(Map<String, dynamic> json) => PlaylistTrack(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        cover: json['cover'] as String?,
      );
}

class Playlist {
  final String id;
  final String name;
  final int createdAt;
  final List<PlaylistTrack> tracks;

  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    this.tracks = const [],
  });

  Playlist copyWith({
    String? id,
    String? name,
    int? createdAt,
    List<PlaylistTrack>? tracks,
  }) =>
      Playlist(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        tracks: tracks ?? this.tracks,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'tracks': tracks.map((t) => t.toJson()).toList(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
        tracks: (json['tracks'] as List<dynamic>? ?? [])
            .map((e) => PlaylistTrack.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

const String downloadsPlaylistId = 'yvl_downloads_v1';
