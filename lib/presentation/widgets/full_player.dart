import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/track.dart';
import '../../data/models/liked_track.dart';
import '../../data/models/playlist.dart';
import '../../data/services/lrclib_service.dart';
import '../../data/models/lyrics.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/likes_provider.dart';
import '../../providers/playlists_provider.dart';
import '../../core/constants/colors.dart';
import 'lyrics_view.dart';

class FullPlayer extends ConsumerStatefulWidget {
  const FullPlayer({super.key});

  @override
  ConsumerState<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends ConsumerState<FullPlayer>
    with TickerProviderStateMixin {
  bool _showLyrics = false;
  Lyrics? _lyrics;
  bool _loadingLyrics = false;
  LyricsMode _lyricsMode = LyricsMode.line;
  late AnimationController _vinylController;
  bool _showPlaylistPicker = false;
  String? _lastTrackId;

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
    _loadLyricsForCurrent();
  }

  @override
  void dispose() {
    _vinylController.dispose();
    super.dispose();
  }

  Future<void> _loadLyricsForCurrent() async {
    final track = ref.read(playerProvider).current;
    if (track == null) return;
    if (track.id == _lastTrackId) return;
    _lastTrackId = track.id;
    setState(() { _lyrics = null; _loadingLyrics = true; });
    try {
      final result = await LrclibService.fetchLyrics(track.title, track.artist, duration: track.duration);
      if (mounted) setState(() { _lyrics = result; _loadingLyrics = false; });
    } catch (_) {
      if (mounted) setState(() { _lyrics = null; _loadingLyrics = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final accent = ref.watch(themeProvider).accent;
    final track = playerState.current;
    if (track == null) return const SizedBox.shrink();

    if (track.id != _lastTrackId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadLyricsForCurrent());
    }

    if (playerState.isPlaying) {
      _vinylController.forward();
    } else {
      _vinylController.stop();
    }

    final liked = ref.watch(likesProvider).any((t) => t.id == track.id);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blurred background
          if (track.cover != null && track.cover!.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: track.cover!,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.5),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.background.withOpacity(0.8), AppColors.background],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      _circleButton(
                        icon: Icons.keyboard_arrow_down,
                        onTap: () => playerNotifier.expand(false),
                      ),
                      const Expanded(
                        child: Column(
                          children: [
                            Text('Now Playing',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted,
                                    letterSpacing: 1.5)),
                            Text('YVL',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      _circleButton(
                        icon: _showLyrics ? Icons.queue_music : Icons.mic,
                        onTap: () => setState(() => _showLyrics = !_showLyrics),
                        active: _showLyrics,
                        accent: accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Hero area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _showLyrics
                        ? _lyricsPanel(playerState, accent)
                        : _vinylPanel(track, playerState, accent),
                  ),
                ),
                if (_showLyrics) _lyricsModePicker(accent),
                const SizedBox(height: 16),
                // Track info + actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900)),
                            Text(track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                      _actionBtn(
                        icon: liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? accent : null,
                        onTap: () {
                          ref.read(likesProvider.notifier).toggle(LikedTrack(
                            id: track.id,
                            title: track.title,
                            artist: track.artist,
                            cover: track.cover,
                            likedAt: DateTime.now().millisecondsSinceEpoch,
                          ));
                        },
                      ),
                      _actionBtn(
                        icon: Icons.add,
                        onTap: () => setState(() => _showPlaylistPicker = true),
                      ),
                      _actionBtn(
                        icon: Icons.download_outlined,
                        onTap: () => _download(track.stream, track.title, track.artist, track.cover, track.id),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Seek bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Slider(
                        value: playerState.duration > 0
                            ? playerState.position.clamp(0, playerState.duration)
                            : 0,
                        max: playerState.duration > 0 ? playerState.duration : 1,
                        onChanged: (v) => playerNotifier.seek(v),
                        activeColor: accent,
                        inactiveColor: AppColors.secondary,
                        thumbColor: accent,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formatDurationDouble(playerState.position),
                                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                            Text(formatDurationDouble(playerState.duration),
                                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: playerNotifier.shufflePlay,
                        icon: const Icon(Icons.shuffle, size: 24),
                        color: AppColors.muted,
                      ),
                      IconButton(
                        onPressed: () async => await playerNotifier.prev(),
                        icon: const Icon(Icons.skip_previous, size: 32),
                        color: AppColors.foreground,
                      ),
                      GestureDetector(
                        onTap: playerNotifier.toggle,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 20, spreadRadius: 4)],
                          ),
                          child: Icon(
                            playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: _contrastColor(accent),
                            size: 32,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async => await playerNotifier.next(),
                        icon: const Icon(Icons.skip_next, size: 32),
                        color: AppColors.foreground,
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_showPlaylistPicker && track != null)
            _PlaylistPickerSheet(
              track: PlaylistTrack(id: track.id, title: track.title, artist: track.artist, cover: track.cover),
              onClose: () => setState(() => _showPlaylistPicker = false),
            ),
        ],
      ),
    );
  }

  Widget _vinylPanel(track, playerState, Color accent) {
    return RotationTransition(
      turns: _vinylController,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.secondary,
          boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (track.cover != null && track.cover!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: track.cover!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              // Vinyl groove overlay
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Colors.transparent, Color(0x2D000000)],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
              // Center hole
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                  border: Border.all(color: accent, width: 3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lyricsPanel(playerState, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: LyricsView(
        lyrics: _lyrics,
        position: playerState.position,
        duration: playerState.duration,
        mode: _lyricsMode,
        loading: _loadingLyrics,
        accent: accent,
        onSeek: ref.read(playerProvider.notifier).seek,
      ),
    );
  }

  Widget _lyricsModePicker(Color accent) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: LyricsMode.values.map((m) {
          final selected = m == _lyricsMode;
          return GestureDetector(
            onTap: () => setState(() => _lyricsMode = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? accent : AppColors.secondary.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(lyricsModesLabels[m]!,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? _contrastColor(accent) : AppColors.muted)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap, bool active = false, Color? accent}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active && accent != null ? accent : AppColors.secondary.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: (active && accent != null) ? _contrastColor(accent) : AppColors.foreground),
      ),
    );
  }

  Widget _actionBtn({required IconData icon, Color? color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color ?? AppColors.foreground),
      ),
    );
  }

  Future<void> _download(String? stream, String title, String artist, String? cover, String id) async {
    if (stream == null || stream.isEmpty) return;
    final track = PlaylistTrack(id: id, title: title, artist: artist, cover: cover);
    await ref.read(playlistsProvider.notifier).addToDownloads(track);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title added to Downloads'), duration: const Duration(seconds: 2)),
      );
    }
  }

  Color _contrastColor(Color bg) {
    return bg.computeLuminance() > 0.4 ? Colors.black : Colors.white;
  }
}

class _PlaylistPickerSheet extends ConsumerStatefulWidget {
  final PlaylistTrack track;
  final VoidCallback onClose;
  const _PlaylistPickerSheet({required this.track, required this.onClose});

  @override
  ConsumerState<_PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends ConsumerState<_PlaylistPickerSheet> {
  bool _creating = false;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(playlistsProvider);
    final notifier = ref.read(playlistsProvider.notifier);
    final accent = ref.watch(themeProvider).accent;

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.secondary, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Add to playlist',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${widget.track.title} · ${widget.track.artist}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_creating)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => setState(() => _creating = true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                                child: Icon(Icons.add, color: _contrastColor(accent)),
                              ),
                              const SizedBox(width: 12),
                              const Text('New playlist', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameCtrl,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Playlist name',
                                hintStyle: const TextStyle(color: AppColors.muted),
                                filled: true,
                                fillColor: AppColors.secondary,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onSubmitted: (_) => _create(notifier),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _create(notifier),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: _contrastColor(accent),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text('Create'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: playlists.length,
                      itemBuilder: (_, i) {
                        final pl = playlists[i];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.queue_music, color: AppColors.muted),
                          ),
                          title: Text(pl.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${pl.tracks.length} tracks',
                              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                          onTap: () async {
                            await notifier.addTrack(pl.id, widget.track);
                            widget.onClose();
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.onClose,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.foreground,
                          side: const BorderSide(color: AppColors.border),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _create(PlaylistsNotifier notifier) async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final pl = await notifier.create(_nameCtrl.text.trim());
    await notifier.addTrack(pl.id, widget.track);
    widget.onClose();
  }

  Color _contrastColor(Color bg) =>
      bg.computeLuminance() > 0.4 ? Colors.black : Colors.white;
}
