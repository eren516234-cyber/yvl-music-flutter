class LikedTrack {
  final String id;
  final String title;
  final String artist;
  final String? cover;
  final int likedAt;

  const LikedTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.cover,
    required this.likedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'cover': cover,
        'likedAt': likedAt,
      };

  factory LikedTrack.fromJson(Map<String, dynamic> json) => LikedTrack(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        cover: json['cover'] as String?,
        likedAt: (json['likedAt'] as num?)?.toInt() ?? 0,
      );
}
