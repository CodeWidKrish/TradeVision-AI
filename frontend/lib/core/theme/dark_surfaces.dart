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
