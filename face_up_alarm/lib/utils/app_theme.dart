// lib/utils/app_theme.dart
// FaceUp Alarm - App Theme
// Ye file poori app ki visual design define karti hai
// Material 3 use kar rahe hain - Google ka latest design system

import 'package:flutter/material.dart';

class AppTheme {
  // ============================================================
  // COLORS - App ke rang
  // ============================================================

  // Primary blue - main color
  static const Color primaryBlue = Color(0xFF2196F3); // Blue 500
  static const Color primaryBlueDark = Color(0xFF1565C0); // Blue 800
  static const Color primaryBlueLight = Color(0xFFBBDEFB); // Blue 100

  // Accent green - success aur ON state ke liye
  static const Color accentGreen = Color(0xFF4CAF50); // Green 500
  static const Color accentGreenLight = Color(0xFFC8E6C9); // Green 100

  // Error red
  static const Color errorRed = Color(0xFFE53935);
  static const Color errorRedLight = Color(0xFFFFCDD2);

  // Warning orange
  static const Color warningOrange = Color(0xFFFFA726);

  // Background
  static const Color background = Color(0xFFF8FAFE); // Almost white with blue tint
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFEEF2FF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E); // Dark navy
  static const Color textSecondary = Color(0xFF6B7280); // Gray
  static const Color textLight = Color(0xFF9CA3AF); // Light gray

  // Alarm card colors
  static const Color alarmCardEnabled = Colors.white;
  static const Color alarmCardDisabled = Color(0xFFF5F5F5);

  // Face verification screen
  static const Color faceGuideActive = Color(0xFF4CAF50);
  static const Color faceGuideInactive = Color(0xFF90CAF9);
  static const Color faceGuideError = Color(0xFFE53935);

  // ============================================================
  // TYPOGRAPHY - Fonts aur text sizes
  // ============================================================

  // Clock display - bari ghari ke liye
  static const TextStyle clockStyle = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w200,
    color: textPrimary,
    letterSpacing: 2,
  );

  // Alarm time in list
  static const TextStyle alarmTimeStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    color: textPrimary,
    letterSpacing: 1,
  );

  // Section headings
  static const TextStyle headingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  // Body text - Urdu aur English dono ke liye
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  // Privacy message
  static const TextStyle privacyStyle = TextStyle(
    fontSize: 12,
    color: textSecondary,
    height: 1.4,
  );

  // ============================================================
  // SPACING - Jagah aur duri
  // ============================================================
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ============================================================
  // BORDER RADIUS - Rounded corners
  // ============================================================
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircle = 100.0;

  // ============================================================
  // SHADOWS - Cheez ko float karne ka effect
  // ============================================================
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // ============================================================
  // MATERIAL THEME DATA
  // Flutter ko batate hain puri app ka theme kya hoga
  // ============================================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: accentGreen,
        surface: surface,
        error: errorRed,
      ),
      scaffoldBackgroundColor: background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // Elevated Button (main buttons)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Switch (alarm ON/OFF toggle)
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentGreen;
          }
          return textLight;
        }),
      ),

      // Card
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
      ),

      // Input (time picker, etc.)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }
}
