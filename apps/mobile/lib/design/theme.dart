import 'package:flutter/material.dart';

/// Grayscale design system. No chroma anywhere: text, surfaces and accents are
/// all neutrals, so colour is never a signalling channel and the UI stays
/// calm for sensory-sensitive users. Emphasis is communicated by weight,
/// contrast and spacing instead.
class ParallelColors {
  ParallelColors._();

  static const ink = Color(0xFF17171A);
  static const inkMuted = Color(0xFF5A5A5E);
  static const paper = Color(0xFFFDFDFC);
  static const canvas = Color(0xFFF4F4F2);
  static const line = Color(0xFFD7D7D4);
  static const lineSoft = Color(0xFFE6E6E3);
  static const accent = Color(0xFF2E2E33);
  static const accentOn = Color(0xFFF7F7F6);
  static const overlay = Color(0xCC17171A);

  /// Accessible grey ramp for status (battery 0..4) and alignment badges.
  static const ramp = [
    Color(0xFF1F1F22),
    Color(0xFF3A3A3E),
    Color(0xFF5C5C60),
    Color(0xFF86868B),
    Color(0xFFB7B7BC),
  ];
}

ThemeData buildParallelTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: ParallelColors.accent,
    brightness: Brightness.light,
  ).copyWith(
    primary: ParallelColors.accent,
    onPrimary: ParallelColors.accentOn,
    secondary: ParallelColors.inkMuted,
    onSecondary: ParallelColors.paper,
    surface: ParallelColors.paper,
    onSurface: ParallelColors.ink,
    outline: ParallelColors.line,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: ParallelColors.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: ParallelColors.canvas,
      foregroundColor: ParallelColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: ParallelColors.paper,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ParallelColors.lineSoft),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    dividerTheme: const DividerThemeData(color: ParallelColors.lineSoft),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ParallelColors.paper,
      indicatorColor: ParallelColors.ink,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ParallelColors.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ParallelColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ParallelColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ParallelColors.ink, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ParallelColors.ink,
        foregroundColor: ParallelColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ParallelColors.ink,
        side: const BorderSide(color: ParallelColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ParallelColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: ParallelColors.overlay,
      contentTextStyle: TextStyle(color: ParallelColors.paper),
      behavior: SnackBarBehavior.floating,
    ),
  );
}