import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lyrics.dart';
import '../../core/constants/colors.dart';

enum LyricsMode { line, word, karaoke, wave, neon, cinema, float, pulse }

const lyricsModesLabels = {
  LyricsMode.line: 'Line',
  LyricsMode.word: 'Word',
  LyricsMode.karaoke: 'Char',
  LyricsMode.wave: 'Wave',
  LyricsMode.neon: 'Neon',
  LyricsMode.cinema: 'Cinema',
  LyricsMode.float: 'Float',
  LyricsMode.pulse: 'Pulse',
};

class LyricsView extends ConsumerStatefulWidget {
  final Lyrics? lyrics;
  final double position;
  final double duration;
  final LyricsMode mode;
  final bool loading;
  final Color accent;
  final void Function(double)? onSeek;

  const LyricsView({
    super.key,
    required this.lyrics,
    required this.position,
    required this.duration,
    required this.mode,
    required this.loading,
    required this.accent,
    this.onSeek,
  });

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> with TickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  bool _userScrolled = false;
  int _lastActive = -1;
  late AnimationController _waveController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  ({int activeLine, double lineProgress}) _compute(List<LyricsLine> synced) {
    if (synced.isEmpty) return (activeLine: -1, lineProgress: 0);
    int idx = -1;
    for (int i = 0; i < synced.length; i++) {
      if (synced[i].time <= widget.position) idx = i;
      else break;
    }
    double progress = 0;
    if (idx >= 0) {
      final start = synced[idx].time;
      final end = idx + 1 < synced.length
          ? synced[idx + 1].time
          : min(start + 5, widget.duration > 0 ? widget.duration : start + 5);
      final span = max(end - start, 0.4);
      progress = min(1.0, max(0.0, (widget.position - start) / span));
    }
    return (activeLine: idx, lineProgress: progress);
  }

  void _scrollToActive(int active) {
    if (!_scroll.hasClients || active < 0 || _userScrolled) return;
    if (active == _lastActive) return;
    _lastActive = active;
    final itemHeight = 60.0;
    final target = active * itemHeight - _scroll.position.viewportDimension / 2 + itemHeight / 2;
    _scroll.animateTo(
      target.clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.lyrics;

    if (widget.loading) {
      return const Center(
        child: Text('Loading lyrics…', style: TextStyle(color: AppColors.muted)),
      );
    }

    if (lyrics == null || (!lyrics.hasSynced && !lyrics.hasPlain)) {
      return const Center(
        child: Text('No lyrics found.', style: TextStyle(color: AppColors.muted)),
      );
    }

    if (!lyrics.hasSynced && lyrics.hasPlain) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(lyrics.plain,
            style: const TextStyle(color: AppColors.foreground, height: 1.7, fontSize: 16)),
      );
    }

    final computed = _compute(lyrics.synced);
    final active = computed.activeLine;
    final progress = computed.lineProgress;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive(active));

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is UserScrollNotification) _userScrolled = true;
            return false;
          },
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.15, 0.85, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 80),
              itemCount: lyrics.synced.length,
              itemBuilder: (ctx, i) {
                final line = lyrics.synced[i];
                return _buildLine(i, line, active, progress);
              },
            ),
          ),
        ),
        if (_userScrolled)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() => _userScrolled = false);
                  _lastActive = -1;
                  _scrollToActive(active);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.my_location, size: 14, color: Colors.black),
                      const SizedBox(width: 6),
                      const Text('Re-sync',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLine(int i, LyricsLine line, int active, double progress) {
    final isActive = i == active;
    final isPast = i < active;
    final text = line.text.isEmpty ? '♪' : line.text;

    Widget lineWidget;
    switch (widget.mode) {
      case LyricsMode.line:
        lineWidget = _LineMode(text: text, isActive: isActive);
      case LyricsMode.word:
        lineWidget = _WordMode(text: text, isActive: isActive, isPast: isPast, progress: progress, accent: widget.accent);
      case LyricsMode.karaoke:
        lineWidget = _KaraokeMode(text: text, isActive: isActive, isPast: isPast, progress: progress, accent: widget.accent);
      case LyricsMode.wave:
        lineWidget = AnimatedBuilder(
          animation: _waveController,
          builder: (_, __) => _WaveMode(text: text, isActive: isActive, t: _waveController.value * 4 * pi, progress: progress, accent: widget.accent),
        );
      case LyricsMode.neon:
        lineWidget = _NeonMode(text: text, isActive: isActive, accent: widget.accent);
      case LyricsMode.cinema:
        lineWidget = _CinemaMode(text: text, isActive: isActive);
      case LyricsMode.float:
        lineWidget = AnimatedBuilder(
          animation: _waveController,
          builder: (_, __) {
            final t = _waveController.value * 2 * pi;
            return _FloatMode(text: text, isActive: isActive, t: t, index: i, accent: widget.accent);
          },
        );
      case LyricsMode.pulse:
        lineWidget = AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => _PulseMode(text: text, isActive: isActive, pulseValue: _pulseController.value, progress: progress, accent: widget.accent),
        );
    }

    return GestureDetector(
      onTap: () {
        widget.onSeek?.call(line.time);
        setState(() => _userScrolled = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: lineWidget,
      ),
    );
  }
}

class _LineMode extends StatelessWidget {
  final String text;
  final bool isActive;
  const _LineMode({required this.text, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: TextStyle(
        fontSize: isActive ? 26 : 24,
        fontWeight: FontWeight.w800,
        color: isActive ? Colors.white : Colors.white.withOpacity(0.45),
        shadows: isActive ? [const Shadow(color: Colors.white38, blurRadius: 20)] : null,
      ),
      child: Text(text, textAlign: TextAlign.left),
    );
  }
}

class _WordMode extends StatelessWidget {
  final String text;
  final bool isActive;
  final bool isPast;
  final double progress;
  final Color accent;
  const _WordMode({required this.text, required this.isActive, required this.isPast, required this.progress, required this.accent});

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    final reveal = isActive ? (progress * words.length) : (isPast ? words.length.toDouble() : 0.0);
    return Wrap(
      children: words.asMap().entries.map((e) {
        final lit = e.key < reveal;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: lit ? accent : Colors.white.withOpacity(0.4),
              shadows: (lit && isActive) ? [Shadow(color: accent.withOpacity(0.6), blurRadius: 16)] : null,
            ),
            child: Text(e.value),
          ),
        );
      }).toList(),
    );
  }
}

class _KaraokeMode extends StatelessWidget {
  final String text;
  final bool isActive;
  final bool isPast;
  final double progress;
  final Color accent;
  const _KaraokeMode({required this.text, required this.isActive, required this.isPast, required this.progress, required this.accent});

  @override
  Widget build(BuildContext context) {
    final chars = text.split('');
    final total = chars.length;
    final reveal = isActive ? (progress * total) : (isPast ? total.toDouble() : 0.0);
    return Wrap(
      children: chars.asMap().entries.map((e) {
        final lit = e.key < reveal;
        final justLit = isActive && lit && e.key >= reveal - 1;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(0, justLit ? -3 : 0, 0)..scale(justLit ? 1.15 : 1.0),
          child: Text(
            e.value == ' ' ? '\u00A0' : e.value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: lit ? accent : Colors.white.withOpacity(0.4),
              shadows: lit ? [Shadow(color: accent, blurRadius: 10)] : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WaveMode extends StatelessWidget {
  final String text;
  final bool isActive;
  final double t;
  final double progress;
  final Color accent;
  const _WaveMode({required this.text, required this.isActive, required this.t, required this.progress, required this.accent});

  @override
  Widget build(BuildContext context) {
    final chars = text.split('');
    return Wrap(
      children: chars.asMap().entries.map((e) {
        final phase = isActive ? sin(t + e.key * 0.35 + progress * 4) * 6.0 : 0.0;
        return Transform.translate(
          offset: Offset(0, phase),
          child: Text(
            e.value == ' ' ? '\u00A0' : e.value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
              shadows: isActive ? [Shadow(color: accent, blurRadius: 12)] : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NeonMode extends StatelessWidget {
  final String text;
  final bool isActive;
  final Color accent;
  const _NeonMode({required this.text, required this.isActive, required this.accent});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 400),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
          shadows: isActive
              ? [
                  Shadow(color: accent, blurRadius: 18),
                  Shadow(color: accent, blurRadius: 40),
                  Shadow(color: accent.withOpacity(0.5), blurRadius: 80),
                ]
              : null,
        ),
      ),
    );
  }
}

class _CinemaMode extends StatelessWidget {
  final String text;
  final bool isActive;
  const _CinemaMode({required this.text, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 500),
      style: TextStyle(
        fontSize: isActive ? 26 : 22,
        fontWeight: FontWeight.w800,
        color: isActive ? Colors.white : Colors.white.withOpacity(0.25),
        shadows: isActive ? [const Shadow(color: Colors.white38, blurRadius: 28)] : null,
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}

class _FloatMode extends StatelessWidget {
  final String text;
  final bool isActive;
  final double t;
  final int index;
  final Color accent;
  const _FloatMode({required this.text, required this.isActive, required this.t, required this.index, required this.accent});

  @override
  Widget build(BuildContext context) {
    final float = sin(t * 0.8 + index * 0.4) * (isActive ? 4 : 2);
    final drift = cos(t * 0.5 + index * 0.7) * (isActive ? 0 : 6);
    return Transform.translate(
      offset: Offset(drift, float),
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : max(0.2, 1.0 - (index * 0.15)),
        duration: const Duration(milliseconds: 300),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isActive ? 26 : 22,
            fontWeight: FontWeight.w800,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            shadows: isActive ? [Shadow(color: accent, blurRadius: 20)] : null,
          ),
        ),
      ),
    );
  }
}

class _PulseMode extends StatelessWidget {
  final String text;
  final bool isActive;
  final double pulseValue;
  final double progress;
  final Color accent;
  const _PulseMode({required this.text, required this.isActive, required this.pulseValue, required this.progress, required this.accent});

  @override
  Widget build(BuildContext context) {
    final beat = sin(progress * pi * 4);
    final scale = isActive ? 1.0 + max(0.0, beat) * 0.08 : 1.0;
    return Transform.scale(
      scale: scale,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.45),
          shadows: isActive
              ? [
                  Shadow(color: accent, blurRadius: 10 + beat * 18),
                  Shadow(color: accent.withOpacity(0.5), blurRadius: 24 + beat * 24),
                ]
              : null,
        ),
      ),
    );
  }
}
