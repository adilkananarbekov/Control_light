import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final palette = AppColors.of(brightness);
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: AppColors.accentCyan,
      primary: AppColors.accentCyan,
      secondary: AppColors.accentPurple,
      tertiary: AppColors.accentGreen,
    ),
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme),
    scaffoldBackgroundColor: palette.background,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: palette.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: palette.glassSurface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor:
          brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(
        color: brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.5)
            : palette.textMuted,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: AppColors.accentCyan.withValues(alpha: 0.18),
      iconTheme: WidgetStateProperty.all(
        IconThemeData(color: palette.textPrimary),
      ),
      labelTextStyle: WidgetStateProperty.all(
        base.textTheme.labelMedium?.copyWith(color: palette.textPrimary),
      ),
    ),
  );
}
