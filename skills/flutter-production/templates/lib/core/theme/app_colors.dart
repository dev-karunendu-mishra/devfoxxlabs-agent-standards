import 'package:flutter/material.dart';

/// Raw palette. The ONLY file allowed to contain `Color(0x…)` literals.
/// Feature code reads colors via `Theme.of(context).colorScheme` or
/// `context.appColors` (see app_theme_extension.dart).
///
/// TODO(brand): replace with the app's brand palette.
class AppColors {
  AppColors._();

  // Brand
  static const Color brand = Color(0xFF1E5A45);
  static const Color brandLight = Color(0xFFDCEFE7);
  static const Color brandDark = Color(0xFF123C32);
  static const Color accent = Color(0xFFFAB304);

  // Light neutrals
  static const Color lightBackground = Color(0xFFF7F7F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF1F2F4);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightBorderSubtle = Color(0xFFF0F1F3);

  // Dark neutrals
  static const Color darkBackground = Color(0xFF0B0C10);
  static const Color darkSurface = Color(0xFF13151B);
  static const Color darkSurfaceSecondary = Color(0xFF1A1D25);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF1E222D);
  static const Color darkBorderSubtle = Color(0xFF171A22);

  // Semantic
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);
}
