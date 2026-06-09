import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/track.dart';
import '../data/services/saavn_service.dart';
import 'settings_provider.dart';

class PlayerState {
  final List<Track> queue;
  final int index;
  final bool isPlaying;
  final double position;
  final double duration;
  final bool expanded;

  const PlayerState({
    this.queue = const [],
    this.index = 0,
    this.isPlaying = false,
    this.position = 0,
    this.duration = 0,
    this.expanded = false,
  });

  Track? get current => (queue.isNotEmpty && index >= 0 && index < queue.length)
      ? queue[index]
      : null;

  PlayerState copyWith({
    List<Track>? queue,
    int? index,
    bool? isPlaying,
    double? position,
    double? duration,
    bool? expanded,
  }) =>
      PlayerState(
        queue: queue ?? this.queue,
        index: index ?? this.index,
        isPlaying: isPlaying ?? this.isPlaying,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        expanded: expanded ?? this.expanded,
      );
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final AudioPlayer _audio = AudioPlayer();
  String _quality;

  PlayerNotifier(this._quality) : super(const PlayerState()) {
    _audio.positionStream.listen((pos) {
      state = state.copyWith(position: pos.inMilliseconds / 1000.0);
    });
    _audio.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur.inMilliseconds / 1000.0);
    });
    _audio.playerStateStream.listen((ps) {
      state = state.copyWith(isPlaying: ps.playing);
      if (ps.processingState == ProcessingState.completed) {
        _goTo(state.index + 1);
      }
    });
  }

  void updateQuality(String q) => _quality = q;

  Future<void> play(List<Track> tracks, {int startIndex = 0}) async {
    state = state.copyWith(queue: tracks, index: startIndex, expanded: true);
    await _loadAt(startIndex, tracks);
  }

  Future<void> _loadAt(int i, List<Track> q) async {
    if (i < 0 || i >= q.length) return;
    var track = q[i];
    if (track.stream == null || track.stream!.isEmpty) {
      try {
        final full = await SaavnService.getSong(track.id, quality: _quality);
        track = track.copyWith(stream: full.stream, duration: full.duration, cover: full.cover ?? track.cover);
        final updatedQueue = [...state.queue];
        updatedQueue[i] = track;
        state = state.copyWith(queue: updatedQueue, index: i);
      } catch (_) {
        return;
      }
    }
    try {
      await _audio.setUrl(track.stream!);
      await _audio.play();
    } catch (_) {}
  }

  Future<void> _goTo(int i) async {
    if (i < 0 || i >= state.queue.length) return;
    state = state.copyWith(index: i);
    await _loadAt(i, state.queue);
  }

  void toggle() {
    if (_audio.playing) {
      _audio.pause();
    } else {
      _audio.play();
    }
  }

  Future<void> next() => _goTo(state.index + 1);
  Future<void> prev() => _goTo(state.index - 1);

  void seek(double seconds) {
    _audio.seek(Duration(milliseconds: (seconds * 1000).toInt()));
    state = state.copyWith(position: seconds);
  }

  void expand(bool v) => state = state.copyWith(expanded: v);

  Future<void> shufflePlay() async {
    if (state.queue.length < 2) return;
    final shuffled = [...state.queue]..shuffle(Random());
    await play(shuffled);
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  final quality = ref.read(qualityProvider).quality;
  final notifier = PlayerNotifier(quality);
  ref.listen(qualityProvider, (_, next) => notifier.updateQuality(next.quality));
  return notifier;
});
