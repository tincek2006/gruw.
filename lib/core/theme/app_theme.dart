import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central color + text style definitions matching the Home / Music / Runs
/// mockups: near-black background with a dark maroon/pink radial glow,
/// pink accent for CTAs and highlights.
class AppColors {
  static const Color background = Color(0xFF120A0D); // near-black
  static const Color glowMaroon = Color(0xFF4A0F26); // radial glow behind cards
  static const Color cardBackground = Color(0x33FFFFFF); // translucent card fill
  static const Color cardBorder = Color(0x1AFFFFFF);
  static const Color accentPink = Color(0xFFE8177A); // "Start run" button, highlights
  static const Color accentPinkSoft = Color(0xFFF2A9C6); // bar chart bars, soft highlights
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCBB8C0);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accentPink,
        surface: AppColors.background,
      ),
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPink,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  /// Reusable "glass card" decoration used for the Home/Music/Runs panels.
  static BoxDecoration cardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.cardBorder),
    );
  }

  /// The radial maroon glow background used behind all three main screens.
  static BoxDecoration get screenBackground {
    return const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -0.2),
        radius: 1.2,
        colors: [
          AppColors.glowMaroon,
          AppColors.background,
        ],
        stops: [0.0, 0.85],
      ),
    );
  }
}
