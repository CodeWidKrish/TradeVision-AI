import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── LIGHT ──────────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0066CC),
          onPrimary: Colors.white,
          secondary: Color(0xFF00C853),
          surface: Color(0xFFF4F6F9),
          onSurface: Color(0xFF1A1A2E),
          outline: Color(0xFFE2E6EA),
          error: Color(0xFFFF3B3B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
          bodyMedium: GoogleFonts.inter(color: const Color(0xFF1A1A2E)),
          labelSmall: GoogleFonts.robotoMono(color: const Color(0xFF8892A4)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.white, // matches light nav bar
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
          titleTextStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E6EA)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E6EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E6EA)),
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
          color: Color(0xFFE2E6EA),
          thickness: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF0066CC),
          unselectedItemColor: Color(0xFF8892A4),
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
