import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';

ThemeData buildAppTheme(Color accent) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.dark(
      background: AppColors.background,
      surface: AppColors.card,
      primary: accent,
      secondary: AppColors.secondary,
      onPrimary: _contrastColor(accent),
      onBackground: AppColors.foreground,
      onSurface: AppColors.foreground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: Colors.transparent,
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: AppColors.foreground);
        }
        return const IconThemeData(color: AppColors.muted);
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(
              color: AppColors.foreground, fontSize: 10, fontWeight: FontWeight.w700);
        }
        return const TextStyle(
            color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w500);
      }),
    ),
    cardTheme: const CardTheme(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accent,
      thumbColor: accent,
      inactiveTrackColor: AppColors.secondary,
      overlayColor: accent.withOpacity(0.2),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((s) =>
          s.contains(MaterialState.selected) ? _contrastColor(accent) : AppColors.muted),
      trackColor: MaterialStateProperty.resolveWith((s) =>
          s.contains(MaterialState.selected) ? accent : AppColors.secondary),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w900),
      displayMedium: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w900),
      headlineLarge: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: AppColors.foreground),
      bodyMedium: TextStyle(color: AppColors.foreground),
      bodySmall: TextStyle(color: AppColors.muted),
    ),
    fontFamily: 'Roboto',
  );
}

Color _contrastColor(Color bg) {
  final luminance = bg.computeLuminance();
  return luminance > 0.4 ? Colors.black : Colors.white;
}
