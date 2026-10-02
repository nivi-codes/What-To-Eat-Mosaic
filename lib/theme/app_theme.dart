import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Moodboard v2 — "bright, but grown-up".
class AppColors {
  // Palette
  static const Color chilli = Color(0xFFE8412C);
  static const Color turmeric = Color(0xFFF5B50F);
  static const Color lime = Color(0xFFC6E34A);
  static const Color blush = Color(0xFFFFB8C9);
  static const Color cobalt = Color(0xFF2D4BFF);
  static const Color cream = Color(0xFFFBF4E6);
  static const Color ink = Color(0xFF10372B);

  static const List<Color> blobs = [chilli, turmeric, lime, blush, cobalt];

  // Roles (used across all screens)
  static const Color background = cream;
  static const Color primary = ink;
  static const Color primaryLight = Color(0xFFEDF5CC); // soft lime
  static const Color accent = chilli;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = ink;
  static const Color textMuted = Color(0xFF5B6E66);
  static const Color bezel = Color(0xFF2C2C2E);
  static const Color cardBorder = ink;
  static const Color tagBg = Color(0xFFEDF5CC);
  static const Color divider = Color(0xFFE3D9C3);
  static const Color success = Color(0xFF3E8E2F);
  static const Color warning = turmeric;
  static const Color error = chilli;
}

class AppTheme {
  static TextStyle font({double? size, FontWeight? weight, Color? color, double? spacing}) => GoogleFonts.interTight(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
      );

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    // Bold, clean type with tight spacing.
    final text = GoogleFonts.interTightTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
        .copyWith(
          displayLarge: font(size: 44, weight: FontWeight.w900, color: AppColors.ink, spacing: -1.6),
          displayMedium: font(size: 38, weight: FontWeight.w900, color: AppColors.ink, spacing: -1.4),
          displaySmall: font(size: 34, weight: FontWeight.w800, color: AppColors.ink, spacing: -1.2),
          headlineLarge: font(size: 32, weight: FontWeight.w800, color: AppColors.ink, spacing: -1),
          headlineMedium: font(size: 28, weight: FontWeight.w800, color: AppColors.ink, spacing: -0.8),
          headlineSmall: font(size: 24, weight: FontWeight.w800, color: AppColors.ink, spacing: -0.6),
          titleLarge: font(size: 20, weight: FontWeight.w800, color: AppColors.ink, spacing: -0.4),
          titleMedium: font(size: 17, weight: FontWeight.w700, color: AppColors.ink, spacing: -0.2),
        );

    const pill = StadiumBorder();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ink,
        primary: AppColors.ink,
        secondary: AppColors.chilli,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: font(size: 20, weight: FontWeight.w800, color: AppColors.ink, spacing: -0.4),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.cream,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: pill,
          textStyle: font(size: 17, weight: FontWeight.w700, spacing: -0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: pill,
          side: const BorderSide(color: AppColors.ink, width: 2),
          textStyle: font(size: 17, weight: FontWeight.w700, spacing: -0.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: font(size: 15, weight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.cream,
        elevation: 0,
        shape: pill,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: font(size: 12, weight: FontWeight.w800),
        unselectedLabelStyle: font(size: 12, weight: FontWeight.w500),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.chilli,
        labelStyle: font(size: 14, weight: FontWeight.w700, color: AppColors.ink),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.ink, width: 2)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: font(size: 14, weight: FontWeight.w600, color: AppColors.cream),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.ink),
    );
  }
}
