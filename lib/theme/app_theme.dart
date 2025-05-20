import 'package:flutter/material.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Color scheme definitions - accessible and healthcare appropriate
  static const Color _primaryColor = Color(0xFF3498db); // Blue - trustworthy, professional
  static const Color _secondaryColor = Color(0xFF2ecc71); // Green - health, positive
  static const Color _accentColor = Color(0xFFf39c12); // Orange - engaging, warm
  static const Color _backgroundColor = Color(0xFFF5F7FA); // Light gray - clean, medical
  static const Color _errorColor = Color(0xFFe74c3c); // Soft red - clear but not alarming
  static const Color _textColor = Color(0xFF2c3e50); // Dark blue-gray - readable

  // Dark theme colors
  static const Color _darkPrimaryColor = Color(0xFF2980b9); // Darker blue
  static const Color _darkSecondaryColor = Color(0xFF27ae60); // Darker green
  static const Color _darkAccentColor = Color(0xFFd35400); // Darker orange
  static const Color _darkBackgroundColor = Color(0xFF1a1a2e); // Dark blue-gray
  static const Color _darkErrorColor = Color(0xFFc0392b); // Darker red
  static const Color _darkTextColor = Color(0xFFecf0f1); // Light gray

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      primary: _primaryColor,
      secondary: _secondaryColor,
      surface: Colors.white,
      background: _backgroundColor,
      error: _errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _textColor,
      onBackground: _textColor,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: _backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _textColor.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _textColor,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: _textColor,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: _textColor,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: _textColor),
      bodyMedium: TextStyle(color: _textColor),
      bodySmall: TextStyle(color: _textColor),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _primaryColor.withOpacity(0.5)),
      ),
    ),
  );

  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      primary: _darkPrimaryColor,
      secondary: _darkSecondaryColor,
      surface: const Color(0xFF2D3748),
      background: _darkBackgroundColor,
      error: _darkErrorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkTextColor,
      onBackground: _darkTextColor,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: _darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2D3748),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF2D3748),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimaryColor,
        side: const BorderSide(color: _darkPrimaryColor),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkPrimaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2D3748),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _darkTextColor.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _darkPrimaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _darkErrorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _darkTextColor,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: _darkTextColor,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: _darkTextColor,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: _darkTextColor),
      bodyMedium: TextStyle(color: _darkTextColor),
      bodySmall: TextStyle(color: _darkTextColor),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2D3748),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _darkPrimaryColor.withOpacity(0.5)),
      ),
    ),
  );
}