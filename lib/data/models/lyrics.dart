class LyricsLine {
  final double time;
  final String text;

  const LyricsLine({required this.time, required this.text});
}

class Lyrics {
  final List<LyricsLine> synced;
  final String plain;

  const Lyrics({required this.synced, required this.plain});

  bool get hasSynced => synced.isNotEmpty;
  bool get hasPlain => plain.isNotEmpty;
}
