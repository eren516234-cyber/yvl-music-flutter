import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF080808);
  static const card = Color(0xFF111111);
  static const secondary = Color(0xFF1A1A1A);
  static const border = Color(0xFF222222);
  static const muted = Color(0xFF666666);
  static const foreground = Color(0xFFFFFFFF);
  static const defaultAccent = Color(0xFFFFFFFF);

  static const customColours = [
    CustomColour(name: 'Coral', hex: '#ff6f61', color: Color(0xFFff6f61)),
    CustomColour(name: 'Yellow', hex: '#ffd23f', color: Color(0xFFffd23f)),
    CustomColour(name: 'Green', hex: '#4ade80', color: Color(0xFF4ade80)),
    CustomColour(name: 'Blue', hex: '#3b82f6', color: Color(0xFF3b82f6)),
    CustomColour(name: 'Pink', hex: '#ec4899', color: Color(0xFFec4899)),
    CustomColour(name: 'Orange', hex: '#f97316', color: Color(0xFFf97316)),
    CustomColour(name: 'Cyan', hex: '#22d3ee', color: Color(0xFF22d3ee)),
    CustomColour(name: 'Red', hex: '#ef4444', color: Color(0xFFef4444)),
  ];
}

class CustomColour {
  final String name;
  final String hex;
  final Color color;

  const CustomColour({required this.name, required this.hex, required this.color});
}

Color hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  if (h.length == 8) return Color(int.parse(h, radix: 16));
  return AppColors.defaultAccent;
}

const perScreenColors = <String, Color>{
  'home': Color(0xFFffd23f),
  'search': Color(0xFF22d3ee),
  'library': Color(0xFF4ade80),
  'settings': Color(0xFFec4899),
  'album': Color(0xFFf97316),
  'artist': Color(0xFF3b82f6),
  'player': Color(0xFFff6f61),
  'explore': Color(0xFF8b5cf6),
};
