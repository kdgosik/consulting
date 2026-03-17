// lib/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Colors ───────────────────────────────────────────────
  static const bg = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const surfaceHigh = Color(0xFF21262D);
  static const border = Color(0xFF30363D);
  static const accent = Color(0xFF58A6FF);
  static const accentGreen = Color(0xFF3FB950);
  static const accentOrange = Color(0xFFF0883E);
  static const accentRed = Color(0xFFF85149);
  static const accentPurple = Color(0xFFBC8CFF);
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);

  static const categoryColors = [
    Color(0xFF58A6FF), // blue
    Color(0xFF3FB950), // green
    Color(0xFFF0883E), // orange
    Color(0xFFBC8CFF), // purple
    Color(0xFFFF7B72), // red
    Color(0xFF39D353), // bright green
    Color(0xFFD29922), // yellow
    Color(0xFF76E3EA), // cyan
  ];

  static Color categoryColor(String category) {
    final hash = category.codeUnits.fold(0, (a, b) => a + b);
    return categoryColors[hash % categoryColors.length];
  }

  // ─── Typography ───────────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.jetBrainsMono(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.jetBrainsMono(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: accent,
          letterSpacing: 0.5,
        ),
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          background: bg,
          surface: surface,
          primary: accent,
          secondary: accentGreen,
          error: accentRed,
        ),
        textTheme: textTheme,
        cardTheme: const CardTheme(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: border),
          ),
        ),
        dividerColor: border,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          labelStyle:
              GoogleFonts.inter(fontSize: 13, color: textSecondary),
          hintStyle: GoogleFonts.inter(fontSize: 13, color: textMuted),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: bg,
            textStyle: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: border),
            textStyle: GoogleFonts.inter(fontSize: 13),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(foregroundColor: textSecondary),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceHigh,
          side: const BorderSide(color: border),
          labelStyle:
              GoogleFonts.inter(fontSize: 12, color: textSecondary),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        scrollbarTheme: const ScrollbarThemeData(
          thumbColor: MaterialStatePropertyAll(border),
        ),
      );
}
