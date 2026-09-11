import 'package:flutter/material.dart';

class AppColors {
  // Brand Accent Colors
  static const primary        = Color(0xFF1B56F1); // Bright Blue — CTA, cards, accents (Light Mode)
  static const primaryLight   = Color(0xFFEFF4FF); // Light Blue tint
  
  // Dark Mode Brand Accent Colors (User Spec: Blue changes into Dark Blue!)
  static const darkPrimary     = Color(0xFF0F2B7A); // Deep Dark Navy Blue
  static const darkPrimaryLight= Color(0xFF132247); // Dark Navy Tint

  // Semantic Trading Colors
  static const gain           = Color(0xFF16A34A); // Emerald Green — positive P&L
  static const gainBg         = Color(0xFFDCFCE7); // Green tint
  static const darkGainBg     = Color(0xFF052E16); // Dark Green tint
  static const loss           = Color(0xFFDC2626); // Crimson Red — negative P&L
  static const lossBg         = Color(0xFFFEE2E2); // Red tint
  static const darkLossBg     = Color(0xFF450A0A); // Dark Red tint
  static const warning        = Color(0xFFD97706); // Amber — neutral signals
  static const warningBg      = Color(0xFFFEF3C7); // Amber tint

  // Semantic Aliases
  static const positive       = gain;
  static const negative       = loss;

  // Light Mode Surfaces & Neutrals (User Spec: White background/surface)
  static const background     = Color(0xFFF8FAFC); // Light background
  static const surface        = Color(0xFFFFFFFF); // Pure White card background
  static const cardBackground = surface;
  static const surfaceElevated= Color(0xFFFFFFFF);
  static const border         = Color(0xFFE2E8F0);
  static const cardBorder     = Color(0xFFCBD5E1);
  static const borderStrong   = Color(0xFF94A3B8);

  // Dark Mode Surfaces & Neutrals (User Spec: White changes into Black!)
  static const darkBackground   = Color(0xFF000000); // Pure Black background
  static const darkSurface      = Color(0xFF0D1117); // Pure Black / Dark Card surface
  static const darkBorder       = Color(0xFF21262D); // Dark Hairline border
  static const darkBorderStrong = Color(0xFF30363D); // Dark Input border

  // Light Mode Typography
  static const textPrimary    = Color(0xFF0F172A); // Slate 900
  static const textSecondary  = Color(0xFF334155); // Slate 700
  static const textMuted      = Color(0xFF475569); // Slate 600
  static const textOnPrimary  = Color(0xFFFFFFFF);

  // Dark Mode Typography (User Spec: Crisp White text in Dark Mode)
  static const darkTextPrimary  = Color(0xFFFFFFFF); // Crisp Pure White
  static const darkTextSecondary= Color(0xFFC9D1D9); // Soft Light Gray
  static const darkTextMuted    = Color(0xFF8B949E); // Muted Gray

  // Stock logo palette
  static const logoReliance   = Color(0xFFFF6900);
  static const logoTCS        = Color(0xFF1B56F1);
  static const logoInfosys    = Color(0xFFD97706);
  static const logoHDFC       = Color(0xFF7C3AED);
  static const logoWipro      = Color(0xFF0891B2);
  static const logoSBI        = Color(0xFF16A34A);
}
