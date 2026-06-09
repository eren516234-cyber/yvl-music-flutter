class Track {
  final String id;
  final String title;
  final String artist;
  final String? artistId;
  final String? albumId;
  final String? cover;
  final int duration;
  final String? stream;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.artistId,
    this.albumId,
    this.cover,
    required this.duration,
    this.stream,
  });

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? artistId,
    String? albumId,
    String? cover,
    int? duration,
    String? stream,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      cover: cover ?? this.cover,
      duration: duration ?? this.duration,
      stream: stream ?? this.stream,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'artistId': artistId,
        'albumId': albumId,
        'cover': cover,
        'duration': duration,
        'stream': stream,
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        artistId: json['artistId'] as String?,
        albumId: json['albumId'] as String?,
        cover: json['cover'] as String?,
        duration: (json['duration'] as num?)?.toInt() ?? 0,
        stream: json['stream'] as String?,
      );
}

String formatDuration(int seconds) {
  if (seconds <= 0) return '0:00';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatDurationDouble(double seconds) {
  if (!seconds.isFinite || seconds < 0) return '0:00';
  return formatDuration(seconds.toInt());
}
