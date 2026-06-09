import 'package:flutter/material.dart';

class Mood {
  final String key;
  final String label;
  final String query;
  final List<Color> gradientColors;

  const Mood({
    required this.key,
    required this.label,
    required this.query,
    required this.gradientColors,
  });
}

const moods = [
  Mood(key: 'chill', label: 'Chill', query: 'chill lofi',
      gradientColors: [Color(0xFF06b6d4), Color(0xFF1d4ed8)]),
  Mood(key: 'party', label: 'Party', query: 'party hits dance',
      gradientColors: [Color(0xFFd946ef), Color(0xFFe11d48)]),
  Mood(key: 'workout', label: 'Workout', query: 'workout gym hype',
      gradientColors: [Color(0xFFf97316), Color(0xFFb91c1c)]),
  Mood(key: 'focus', label: 'Focus', query: 'instrumental focus',
      gradientColors: [Color(0xFF10b981), Color(0xFF0f766e)]),
  Mood(key: 'romance', label: 'Romance', query: 'romantic love songs',
      gradientColors: [Color(0xFFec4899), Color(0xFFbe123c)]),
  Mood(key: 'drive', label: 'Drive', query: 'road trip driving',
      gradientColors: [Color(0xFFf59e0b), Color(0xFFea580c)]),
  Mood(key: 'sleep', label: 'Sleep', query: 'sleep ambient',
      gradientColors: [Color(0xFF6366f1), Color(0xFF5b21b6)]),
  Mood(key: 'throwback', label: 'Throwback', query: '2000s hits throwback',
      gradientColors: [Color(0xFF8b5cf6), Color(0xFF6d28d9)]),
];

const homeTabs = [
  HomeTab(key: 'for-you', label: 'For you', query: 'top hits 2026'),
  HomeTab(key: 'rock', label: 'Rock', query: 'rock hits'),
  HomeTab(key: 'hip-hop', label: 'Hip-hop', query: 'hip hop hits'),
  HomeTab(key: 'k-pop', label: 'K-Pop', query: 'k-pop hits'),
  HomeTab(key: 'pop', label: 'Pop', query: 'pop hits'),
  HomeTab(key: 'bolly', label: 'Bolly', query: 'bollywood hits 2026'),
  HomeTab(key: 'lofi', label: 'Lo-Fi', query: 'lofi chill'),
  HomeTab(key: 'rnb', label: 'R&B', query: 'rnb hits'),
];

class HomeTab {
  final String key;
  final String label;
  final String query;
  const HomeTab({required this.key, required this.label, required this.query});
}

const searchGenres = ['Pop', 'Hip-Hop', 'Rock', 'R&B', 'K-Pop', 'Electronic', 'Jazz', 'Lo-Fi'];
const trendingQueries = ['trending 2026', 'global top 50', 'new releases', 'viral hits'];
