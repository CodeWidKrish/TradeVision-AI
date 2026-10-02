import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── LIGHT (Executive Wall Street / Ceramic Slate Edition) ───────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1E40AF), // Deep Institutional Cobalt / Royal Navy
          onPrimary: Colors.white,
          secondary: Color(0xFF059669), // Crisp Emerald
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF0F172A),
          outline: Color(0xFFE2E8F0),
          error: Color(0xFFDC2626), // Refined Crimson
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Soothing Ceramic Pearl
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          bodyMedium: GoogleFonts.inter(color: const Color(0xFF334155)),
          labelSmall: GoogleFonts.robotoMono(color: const Color(0xFF64748B)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E40AF),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            elevation: 0,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE2E8F0),
          thickness: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1E40AF),
          unselectedItemColor: Color(0xFF64748B),
          elevation: 0,
        ),
      );

  // ── DARK ───────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0066CC),
          onPrimary: Colors.white,
          secondary: Color(0xFF00C853),
          surface: Color(0xFF111827),
          onSurface: Color(0xFFE8ECF0),
          outline: Color(0xFF1E2A3A),
          error: Color(0xFFFF3B3B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: const Color(0xFFE8ECF0)),
          bodyMedium: GoogleFonts.inter(color: const Color(0xFFE8ECF0)),
          labelSmall:
              GoogleFonts.robotoMono(color: const Color(0xFF8892A4)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF111827),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFF111827), // matches dark nav bar
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          iconTheme: const IconThemeData(color: Color(0xFFE8ECF0)),
          titleTextStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xFFE8ECF0),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF111827),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E2A3A)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF111827),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E2A3A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E2A3A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0066CC), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF3B3B)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0066CC),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            elevation: 0,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF1E2A3A),
          thickness: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF111827),
          selectedItemColor: Color(0xFF0066CC),
          unselectedItemColor: Color(0xFF8892A4),
          elevation: 0,
        ),
      );
}

ThemeData appTheme() => AppTheme.light;
ThemeData darkAppTheme() => AppTheme.dark;
