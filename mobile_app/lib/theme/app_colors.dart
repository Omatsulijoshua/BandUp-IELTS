import 'package:flutter/material.dart';

/// Centralized color palette for BandUp IELTS: Black & White with Crimson Red Accent.
class AppColors {
  // Pure Monochromatic Base
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Backgrounds & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFE2E8F0);
  
  // Backgrounds & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF0B0F17);
  static const Color surfaceDark = Color(0xFF161E2E);
  static const Color cardBorderDark = Color(0xFF1E293B);

  // Primary & Secondary Text
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // 3rd Accent Color: Crimson Red
  static const Color accent = Color(0xFFC62828);
  static const Color accentLight = Color(0xFFEF4444);
  static const Color accentDark = Color(0xFF991B1B);
  static const Color accentBgLight = Color(0xFFFEF2F2);
  static const Color accentBgDark = Color(0xFF3F1212);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
}
