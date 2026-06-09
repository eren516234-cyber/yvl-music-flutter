import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lyrics.dart';

List<LyricsLine> _parseLrc(String lrc) {
  final lines = <LyricsLine>[];
  final re = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)');
  for (final raw in lrc.split(RegExp(r'\r?\n'))) {
    for (final m in re.allMatches(raw)) {
      final min = int.parse(m.group(1)!);
      final sec = double.parse(m.group(2)!);
      final text = m.group(3)?.trim() ?? '';
      lines.add(LyricsLine(time: min * 60 + sec, text: text));
    }
  }
  lines.sort((a, b) => a.time.compareTo(b.time));
  return lines;
}

class LrclibService {
  static Future<Lyrics?> fetchLyrics(
      String trackName, String artistName, {int? duration}) async {
    try {
      final params = <String, String>{
        'track_name': trackName,
        'artist_name': artistName,
      };
      if (duration != null) params['duration'] = '$duration';
      var uri = Uri.https('lrclib.net', '/api/get', params);
      var res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 404) {
        final searchUri = Uri.https('lrclib.net', '/api/search', {
          'track_name': trackName,
          'artist_name': artistName,
        });
        final r2 = await http.get(searchUri).timeout(const Duration(seconds: 10));
        if (!r2.ok) return null;
        final arr = jsonDecode(r2.body) as List;
        if (arr.isEmpty) return null;
        final hit = arr.first as Map<String, dynamic>;
        return Lyrics(
          synced: hit['syncedLyrics'] != null
              ? _parseLrc(hit['syncedLyrics'] as String)
              : [],
          plain: hit['plainLyrics']?.toString() ?? '',
        );
      }
      if (!res.ok) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Lyrics(
        synced: data['syncedLyrics'] != null
            ? _parseLrc(data['syncedLyrics'] as String)
            : [],
        plain: data['plainLyrics']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

extension on http.Response {
  bool get ok => statusCode >= 200 && statusCode < 300;
}
