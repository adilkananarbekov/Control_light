import 'package:flutter/material.dart';

/// Central palette for the app. Adjust these in one place to reskin the UI.
class AppPalette {
  final Color background;
  final Color backgroundAlt;
  final Color backgroundSoft;
  final Color backgroundAdmin;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color glassSurface;
  final Color glassBorder;
  final Color glassShadow;
  final Color navSurface;
  final Color navBorder;

  const AppPalette({
    required this.background,
    required this.backgroundAlt,
    required this.backgroundSoft,
    required this.backgroundAdmin,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.glassSurface,
    required this.glassBorder,
    required this.glassShadow,
    required this.navSurface,
    required this.navBorder,
  });
}

class AppColors {
  // Accents are shared between themes.
  static const accentCyan = Color(0xFF4DD0E1);
  static const accentPurple = Color(0xFF7C4DFF);
  static const accentGreen = Color(0xFF00C853);

  static const danger = Colors.redAccent;
  static const warning = Colors.orangeAccent;
  static const success = Colors.greenAccent;

  static const AppPalette light = AppPalette(
    background: Color(0xFFF5F8FF),
    backgroundAlt: Color(0xFFE9F0FF),
    backgroundSoft: Color(0xFFE4E8F5),
    backgroundAdmin: Color(0xFFDDE4F8),
    textPrimary: Color(0xFF0C1329),
    textSecondary: Color(0xFF3C4562),
    textMuted: Color(0xFF5B6686),
    glassSurface: Color(0xCCFFFFFF),
    glassBorder: Color(0x220C1329),
    glassShadow: Colors.black26,
    navSurface: Color(0xFFFFFFFF),
    navBorder: Color(0x110C1329),
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF0A0F1F),
    backgroundAlt: Color(0xFF0C1329),
    backgroundSoft: Color(0xFF101633),
    backgroundAdmin: Color(0xFF0F1533),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    textMuted: Colors.white60,
    glassSurface: Colors.white10,
    glassBorder: Colors.white12,
    glassShadow: Colors.black38,
    navSurface: Color(0xFF0E1529),
    navBorder: Color(0x22000000),
  );

  static AppPalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
