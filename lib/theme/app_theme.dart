import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core palette ──────────────────────────────────────────
  static const Color primary      = Color(0xFFD4AF6A); // warm gold
  static const Color primaryLight = Color(0xFF1E1A10); // dark gold tint bg
  static const Color primaryDark  = Color(0xFFB8903E); // deeper gold
  static const Color surface      = Color(0xFF111111); // card surface
  static const Color background   = Color(0xFF0A0A0A); // page bg
  static const Color textPrimary  = Color(0xFFFFFFFF); // pure white
  static const Color textSecondary= Color(0xFF999999); // muted
  static const Color textHint     = Color(0xFF555555); // dim
  static const Color border       = Color(0xFF242424); // subtle border
  static const Color success      = Color(0xFF4CAF76); // emerald green
  static const Color successLight = Color(0xFF0D1F14); // dark green tint
  static const Color warning      = Color(0xFFE6A817); // amber
  static const Color warningLight = Color(0xFF1F1700); // dark amber tint

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          onPrimary: Color(0xFF0A0A0A),
          surface: surface,
          onSurface: textPrimary,
          outline: border,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: background,
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: textPrimary,
            fontSize: 18,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: const Color(0xFF0A0A0A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.outfit(
                fontSize: 15, fontWeight: FontWeight.w700),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.outfit(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 0.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF161616),
          hintStyle: const TextStyle(color: textHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
        ),
        dividerTheme: const DividerThemeData(color: border, thickness: 0.5),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surface,
          contentTextStyle: GoogleFonts.outfit(color: textPrimary),
        ),
      );
}