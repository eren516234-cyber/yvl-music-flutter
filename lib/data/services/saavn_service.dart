import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';
import '../models/album.dart';
import '../models/artist.dart';

const List<String> _bases = [
  'https://saavn.dev/api',
  'https://jiosaavn-api-privatecvc2.vercel.app/api',
  'https://meloapi.vercel.app/api',
];

String _bestImage(List<dynamic>? images) {
  if (images == null || images.isEmpty) return '';
  const order = ['500x500', 'high', 'large', 'medium', '150x150', 'low'];
  for (final q in order) {
    for (final img in images) {
      final quality = img['quality']?.toString() ?? '';
      if (quality == q || quality.contains(q)) {
        return (img['url']?.toString() ?? '').replaceAll('http://', 'https://');
      }
    }
  }
  final last = images.last['url']?.toString() ?? '';
  return last.replaceAll('http://', 'https://');
}

String _bestStream(List<dynamic>? urls, {String preferred = '320kbps'}) {
  if (urls == null || urls.isEmpty) return '';
  String? pick;
  for (final u in urls) {
    final q = u['quality']?.toString().toLowerCase() ?? '';
    if (q == preferred.toLowerCase()) {
      pick = u['url']?.toString();
      break;
    }
  }
  pick ??= urls
      .firstWhere((u) => u['quality']?.toString().toLowerCase() == '320kbps',
          orElse: () => {})['url']
      ?.toString();
  pick ??= urls
      .firstWhere((u) => u['quality']?.toString().toLowerCase() == '160kbps',
          orElse: () => {})['url']
      ?.toString();
  pick ??= urls.last['url']?.toString();
  return (pick ?? '').replaceAll('http://', 'https://');
}

String _primaryArtist(Map<String, dynamic>? data) {
  final artists = data?['artists'];
  if (artists is Map) {
    final primary = artists['primary'];
    if (primary is List && primary.isNotEmpty) {
      return primary.first['name']?.toString() ?? 'Unknown';
    }
    final all = artists['all'];
    if (all is List && all.isNotEmpty) {
      return all.first['name']?.toString() ?? 'Unknown';
    }
  }
  return 'Unknown';
}

Track _trackFromJson(Map<String, dynamic> s, {String quality = '320kbps'}) {
  final artists = s['artists'];
  String artistId = '';
  if (artists is Map) {
    final primary = artists['primary'];
    if (primary is List && primary.isNotEmpty) {
      artistId = primary.first['id']?.toString() ?? '';
    }
  }
  return Track(
    id: s['id']?.toString() ?? '',
    title: s['name']?.toString() ?? '',
    artist: _primaryArtist(s),
    artistId: artistId.isEmpty ? null : artistId,
    albumId: (s['album'] is Map) ? s['album']['id']?.toString() : null,
    cover: _bestImage(s['image'] as List?),
    duration: (s['duration'] as num?)?.toInt() ?? 0,
    stream: _bestStream(s['downloadUrl'] as List?, preferred: quality),
  );
}

Future<Map<String, dynamic>> _get(
    String path, Map<String, String> params) async {
  dynamic lastErr;
  for (final base in _bases) {
    try {
      final uri = Uri.parse('$base$path').replace(queryParameters: params);
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == false) throw Exception('success=false');
      return body;
    } catch (e) {
      lastErr = e;
    }
  }
  throw lastErr ?? Exception('All Saavn endpoints failed');
}

class SaavnService {
  static Future<List<Track>> searchSongs(String query,
      {int limit = 20, String quality = '320kbps'}) async {
    final body = await _get('/search/songs', {'query': query, 'limit': '$limit'});
    final data = body['data'];
    final results = (data is Map ? data['results'] : null) as List?;
    return (results ?? []).map((s) => _trackFromJson(s as Map<String, dynamic>, quality: quality)).toList();
  }

  static Future<List<AlbumSummary>> searchAlbums(String query,
      {int limit = 20}) async {
    final body = await _get('/search/albums', {'query': query, 'limit': '$limit'});
    final data = body['data'];
    final results = (data is Map ? data['results'] : null) as List?;
    return (results ?? []).map((a) {
      final m = a as Map<String, dynamic>;
      return AlbumSummary(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        cover: _bestImage(m['image'] as List?),
        primaryArtist: _primaryArtist(m),
        year: m['year']?.toString(),
      );
    }).toList();
  }

  static Future<List<ArtistSummary>> searchArtists(String query,
      {int limit = 20}) async {
    final body = await _get('/search/artists', {'query': query, 'limit': '$limit'});
    final data = body['data'];
    final results = (data is Map ? data['results'] : null) as List?;
    return (results ?? []).map((a) {
      final m = a as Map<String, dynamic>;
      return ArtistSummary(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        cover: _bestImage(m['image'] as List?),
      );
    }).toList();
  }

  static Future<Track> getSong(String id, {String quality = '320kbps'}) async {
    final body = await _get('/songs', {'id': id});
    final data = body['data'];
    List<dynamic>? songs;
    if (data is List) {
      songs = data;
    } else if (data is Map) {
      songs = data['songs'] as List?;
    }
    if (songs == null || songs.isEmpty) throw Exception('Song not found');
    return _trackFromJson(songs.first as Map<String, dynamic>, quality: quality);
  }

  static Future<Album> getAlbum(String id,
      {String quality = '320kbps'}) async {
    final body = await _get('/albums', {'id': id});
    final data = body['data'] as Map<String, dynamic>;
    final songs = (data['songs'] as List? ?? [])
        .map((s) => _trackFromJson(s as Map<String, dynamic>, quality: quality))
        .toList();
    return Album(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      year: data['year']?.toString(),
      songCount: (data['songCount'] as num?)?.toInt(),
      cover: _bestImage(data['image'] as List?),
      primaryArtist: _primaryArtist(data),
      songs: songs,
    );
  }

  static Future<Artist> getArtist(String id,
      {String quality = '320kbps'}) async {
    final body = await _get('/artists', {'id': id});
    final data = body['data'] as Map<String, dynamic>;
    final topSongs = (data['topSongs'] as List? ?? [])
        .map((s) => _trackFromJson(s as Map<String, dynamic>, quality: quality))
        .toList();
    final topAlbums = (data['topAlbums'] as List? ?? []).map((a) {
      final m = a as Map<String, dynamic>;
      return AlbumSummary(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        cover: _bestImage(m['image'] as List?),
        primaryArtist: _primaryArtist(m),
        year: m['year']?.toString(),
      );
    }).toList();
    return Artist(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      cover: _bestImage(data['image'] as List?),
      followerCount: (data['followerCount'] as num?)?.toInt(),
      topSongs: topSongs,
      topAlbums: topAlbums,
    );
  }
}
