import 'package:flutter/material.dart';

/// Dark Mode Elevation System for TradeVision AI
class DarkSurface {
  // Level 0 — Page background (deepest canvas)
  static const bg = Color(0xFF0A0E1A);

  // Level 1 — Cards, list rows, bottom nav
  static const card = Color(0xFF111827);

  // Level 2 — Elevated cards (portfolio card, featured sections)
  static const elevated = Color(0xFF1A2332);

  // Level 3 — Input fields, pressed states, inner panels
  static const panel = Color(0xFF1E2A3A);

  // Level 4 — Chips, tags, mini badges
  static const chip = Color(0xFF243040);

  // Borders — subtle separation
  static const border = Color(0xFF1E2733);       // default border
  static const borderActive = Color(0xFF2A3A50); // active/focused border

  // Text Colors (Dark Mode Text Hierarchy)
  static const textPrimary = Color(0xFFE8ECF0);  // Near-white, NOT pure white
  static const textMuted = Color(0xFF8892A4);    // Muted secondary text
  static const textDisabled = Color(0xFF4A5568); // Disabled text
}

/// Light Mode Elevation System for TradeVision AI (Soothing Ceramic, Zero Eye Strain)
class LightSurface {
  // Level 0 — Page background (warm ceramic pearl, eliminates blinding white glare)
  static const bg = Color(0xFFF8FAFC);

  // Level 1 — Cards, list rows, bottom nav
  static const card = Color(0xFFFFFFFF);

  // Level 2 — Elevated cards
  static const elevated = Color(0xFFFFFFFF);

  // Level 3 — Input fields, pressed states, inner panels
  static const panel = Color(0xFFF1F5F9);

  // Level 4 — Chips, tags, mini badges
  static const chip = Color(0xFFEEF2F6);

  // Borders — subtle, refined separation
  static const border = Color(0xFFE2E8F0);       // default subtle slate border
  static const borderActive = Color(0xFFCBD5E1); // active/focused border

  // Text Colors (Light Mode Text Hierarchy - Crisp Slate, Never Washed Out)
  static const textPrimary = Color(0xFF0F172A);  // Deep Slate 900
  static const textSecondary = Color(0xFF334155); // Slate 700
  static const textMuted = Color(0xFF64748B);    // Slate 500
  static const textDisabled = Color(0xFF94A3B8); // Slate 400

  // Soft Ambient Card Shadows
  static const cardShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];
}

/// Adaptive Helper for Seamless Light/Dark Mode Switching
class AppSurface {
  static Color bg(bool isDark) => isDark ? DarkSurface.bg : LightSurface.bg;
  static Color card(bool isDark) => isDark ? DarkSurface.card : LightSurface.card;
  static Color elevated(bool isDark) => isDark ? DarkSurface.elevated : LightSurface.elevated;
  static Color panel(bool isDark) => isDark ? DarkSurface.panel : LightSurface.panel;
  static Color chip(bool isDark) => isDark ? DarkSurface.chip : LightSurface.chip;
  static Color border(bool isDark) => isDark ? DarkSurface.border : LightSurface.border;
  static Color textPrimary(bool isDark) => isDark ? DarkSurface.textPrimary : LightSurface.textPrimary;
  static Color textMuted(bool isDark) => isDark ? DarkSurface.textMuted : LightSurface.textMuted;
}
