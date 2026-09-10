import 'package:flutter/material.dart';

/// Centralized color palette for BandUp IELTS: Option 2: Calm & Encouraging (Mint & Slate)
/// - Primary: Deep Teal (#0F766E) — top bars, key headings, active states.
/// - Secondary / Surface Tint: Soft Sage / Mint (#E6F4F1) — correct answer highlights, cards, completed test pills.
/// - Accent: Coral / Apricot (#F97316) — timer alerts, "Submit" actions, streak badges.
/// - Background: Pale Mist (#F9FBFA) — clean canvas that keeps the UI soft and low-contrast.
/// - Text: Charcoal (#1F2937).
class AppColors {
  // Pure Monochromatic Base
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Backgrounds & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF9FBFA); // Pale Mist
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFFE6F4F1); // Soft Sage / Mint
  static const Color cardBorderLight = Color(0xFFE2E8F0);
  
  // Backgrounds & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF0A1E1D); // Deep Slate Teal Dark
  static const Color surfaceDark = Color(0xFF132F2D);
  static const Color cardBorderDark = Color(0xFF1D423F);

  // Primary: Deep Teal (#0F766E) — top bars, key headings, active states
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryBgLight = Color(0xFFE6F4F1); // Soft Sage / Mint
  static const Color primaryBgDark = Color(0xFF0D3330);

  // Secondary / Surface Tint: Soft Sage / Mint (#E6F4F1)
  static const Color secondary = Color(0xFFE6F4F1);
  static const Color secondaryLight = Color(0xFFF0FDF4);
  static const Color secondaryDark = Color(0xFF2DD4BF);
  static const Color softSage = Color(0xFFE6F4F1);
  static const Color sageText = Color(0xFF0F766E);

  // Accent: Coral / Apricot (#F97316) — timer alerts, "Submit" actions, streak badges
  static const Color accent = Color(0xFFF97316);
  static const Color accentLight = Color(0xFFFB923C);
  static const Color accentDark = Color(0xFFEA580C);
  static const Color accentBgLight = Color(0xFFFFF7ED);
  static const Color accentBgDark = Color(0xFF431407);

  // Primary & Secondary Text: Charcoal (#1F2937)
  static const Color textPrimaryLight = Color(0xFF1F2937); // Charcoal
  static const Color textSecondaryLight = Color(0xFF4B5563);
  static const Color textPrimaryDark = Color(0xFFF9FBFA);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Status Colors
  static const Color success = Color(0xFF0F766E); // Deep Teal
  static const Color successBg = Color(0xFFE6F4F1); // Soft Sage
  static const Color warning = Color(0xFFF97316); // Coral
  static const Color warningBg = Color(0xFFFFF7ED);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEE2E2);
}
