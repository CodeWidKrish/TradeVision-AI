import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Display
  static const portfolioValue = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w800,
    letterSpacing: -0.5, color: AppColors.textOnPrimary,
  );
  static const chartPrice = TextStyle(
    fontSize: 30, fontWeight: FontWeight.w700,
    letterSpacing: -1.0, color: AppColors.textPrimary,
  );

  // Headings
  static const screenTitle = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const sectionTitle = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const cardTitle = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textOnPrimary,
  );

  // Body
  static const stockName = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const stockSubname = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted,
  );
  static const stockPrice = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const bodyMedium = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
  );
  static const bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
    height: 1.5,
  );

  // Labels / Captions
  static const label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted,
  );
  static const labelUppercase = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary,
    letterSpacing: 0.5,
  );
  static const caption = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.textMuted,
  );

  // Change indicators
  static const changePositive = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gain,
  );
  static const changeNegative = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.loss,
  );
}
