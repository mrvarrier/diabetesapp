// File: lib/core/utils/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryColor = Color(0xFF3F88C5);      // Soft blue - primary brand color
  static const Color primaryLight = Color(0xFF64A6E1);      // Lighter variant for highlights
  static const Color primaryDark = Color(0xFF236BAD);       // Darker variant for emphasis

  // Secondary colors
  static const Color secondaryColor = Color(0xFF44BBA4);    // Teal green - supporting color
  static const Color secondaryLight = Color(0xFF6DD3BE);    // Lighter teal for accents
  static const Color secondaryDark = Color(0xFF2A9D87);     // Darker teal for depth

  // Accent colors
  static const Color accentColor = Color(0xFFF6AE2D);       // Warm yellow for important actions/alerts
  static const Color accentLight = Color(0xFFF9C969);       // Light yellow for subtle highlights

  // Neutral colors
  static const Color background = Color(0xFFF7F9FC);        // Light background
  static const Color surface = Color(0xFFFFFFFF);           // Surface color (cards, etc.)
  static const Color textPrimary = Color(0xFF2D3142);       // Primary text color
  static const Color textSecondary = Color(0xFF5C6273);     // Secondary text color
  static const Color textTertiary = Color(0xFF8F95A8);      // Tertiary text color
  static const Color divider = Color(0xFFE1E5EE);           // Divider color

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);           // Success state
  static const Color error = Color(0xFFE63946);             // Error state
  static const Color warning = Color(0xFFF9A825);           // Warning state
  static const Color info = Color(0xFF2196F3);              // Information state

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);    // Dark mode background
  static const Color darkSurface = Color(0xFF1E1E1E);       // Dark mode surface
  static const Color darkTextPrimary = Color(0xFFF0F0F0);   // Dark mode primary text
  static const Color darkTextSecondary = Color(0xFFB8B8B8); // Dark mode secondary text
  static const Color darkDivider = Color(0xFF323232);       // Dark mode divider

  // Specific UI elements
  static const Color progressBarBackground = Color(0xFFE1E5EE);
  static const Color progressBarFill = primaryColor;
  static const Color achievementBadgeBorder = Color(0xFFFFD700);
  static const Color cardBorder = Color(0xFFE1E5EE);
}