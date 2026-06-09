import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/moods.dart';
import '../../data/models/track.dart';
import '../../data/models/album.dart';
import '../../data/models/artist.dart';
import '../../data/services/saavn_service.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/recent_searches_provider.dart';
import '../widgets/song_row.dart';
import '../widgets/album_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _submitted = '';
  List<Track> _songs = [];
  List<AlbumSummary> _albums = [];
  List<ArtistSummary> _artists = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).registerRoute('search');
      if (widget.initialQuery.isNotEmpty) {
        _ctrl.text = widget.initialQuery;
        _submit(widget.initialQuery);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit(String term) async {
    final t = term.trim();
    if (t.isEmpty) return;
    setState(() { _submitted = t; _loading = true; });
    await ref.read(recentSearchesProvider.notifier).add(t);
    try {
      final results = await Future.wait([
        SaavnService.searchSongs(t, limit: 30, quality: ref.read(qualityProvider).quality),
        SaavnService.searchAlbums(t, limit: 10),
        SaavnService.searchArtists(t, limit: 10),
      ]);
      if (mounted) {
        setState(() {
          _songs = results[0] as List<Track>;
          _albums = results[1] as List<AlbumSummary>;
          _artists = results[2] as List<ArtistSummary>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clear() {
    setState(() { _ctrl.clear(); _submitted = ''; _songs = []; _albums = []; _artists = []; });
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(recentSearchesProvider);
    final accent = ref.watch(themeProvider).accent;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
            child: const Text('Search',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(Icons.search, color: AppColors.muted, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Songs, artists, albums…',
                        hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: _submit,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clear,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(Icons.close, color: AppColors.muted, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // No query — show recent + browse
        if (_submitted.isEmpty) ...[
          if (recent.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text('RECENT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppColors.muted, letterSpacing: 2)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recent.map((r) => GestureDetector(
                    onTap: () { _ctrl.text = r; _submit(r); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history, size: 14, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Text(r, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => ref.read(recentSearchesProvider.notifier).remove(r),
                            child: const Icon(Icons.close, size: 13, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: const Text('Browse',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemCount: searchGenres.length,
                itemBuilder: (ctx, i) {
                  final g = searchGenres[i];
                  return GestureDetector(
                    onTap: () { _ctrl.text = g; _submit(g); },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.card, accent.withOpacity(0.15)],
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(16),
                      child: Text(g,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        // Results
        if (_submitted.isNotEmpty) ...[
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else ...[
            if (_artists.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text('Artists', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _artists.length,
                    itemBuilder: (ctx, i) {
                      final a = _artists[i];
                      return GestureDetector(
                        onTap: () => context.push('/artist/${a.id}'),
                        child: SizedBox(
                          width: 80,
                          child: Column(
                            children: [
                              ClipOval(
                                child: a.cover != null && a.cover!.isNotEmpty
                                    ? CachedNetworkImage(imageUrl: a.cover!, width: 64, height: 64, fit: BoxFit.cover)
                                    : Container(width: 64, height: 64, color: AppColors.secondary,
                                        child: const Icon(Icons.person, color: AppColors.muted)),
                              ),
                              const SizedBox(height: 6),
                              Text(a.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            if (_albums.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text('Albums', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _albums.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: AlbumCard(album: _albums[i], size: 150),
                    ),
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text('Songs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
            ),
            if (_songs.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('No results.', style: TextStyle(color: AppColors.muted)),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SongRow(song: _songs[i], queue: _songs),
                  ),
                  childCount: _songs.length,
                ),
              ),
          ],
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
