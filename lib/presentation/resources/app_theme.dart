// This file contains the main theme data for the app. Use AppTheme.lightTheme and AppTheme.darkTheme in MaterialApp.
import 'package:flutter/material.dart';

class AppTheme {
  // Define the blue color palette
  static const Color primaryBlue = Color(0xFF1565C0); // Main blue
  static const Color lightBlue = Color(0xFF42A5F5); // Lighter blue
  static const Color darkBlue = Color(0xFF0D47A1); // Darker blue
  static const Color accentBlue = Color(0xFF2196F3); // Accent blue

  // Monochrome grays
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);
  static const Color darkGray = Color(0xFF424242);
  static const Color charcoal = Color(0xFF212121);

  static const Color lightThemeMoneyColor = Color(0xFF2E7D32);
  static const Color darkThemeMoneyColor = Color(0xFF66BB6A);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: lightBlue,
      onSecondary: Colors.white,
      tertiary: lightThemeMoneyColor,
      onTertiary: Colors.white,
      primaryContainer: Color(0xFFE3F2FD), // Very light blue
      secondaryContainer: Color(0xFFBBDEFB), // Light blue container
      surface: Colors.white,
      onSurface: charcoal,
      onSurfaceVariant: darkGray,
      error: Color(0xFFD32F2F),
      onError: Colors.white,
      outline: mediumGray,
      shadow: Color(0x1A000000),
      surfaceContainerHighest: lightGray,
      onPrimaryContainer: darkBlue,
      onSecondaryContainer: darkBlue,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shadowColor: primaryBlue.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: charcoal,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        color: charcoal,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: charcoal),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: darkGray),
      hintStyle: const TextStyle(color: mediumGray),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryBlue,
      unselectedItemColor: mediumGray,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: charcoal, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: charcoal, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: charcoal, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: charcoal, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: charcoal, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: charcoal, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: charcoal, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: charcoal, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: charcoal, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: charcoal),
      bodyMedium: TextStyle(color: charcoal),
      bodySmall: TextStyle(color: darkGray),
      labelLarge: TextStyle(color: primaryBlue, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: darkGray),
      labelSmall: TextStyle(color: mediumGray),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: lightBlue,
      onPrimary: charcoal,
      secondary: accentBlue,
      onSecondary: charcoal,
      tertiary: darkThemeMoneyColor,
      onTertiary: charcoal,
      primaryContainer: darkBlue,
      secondaryContainer: Color(0xFF1976D2),
      surface: Color(0xFF1A1A1A),
      onSurface: Colors.white,
      onSurfaceVariant: Color(0xFFE0E0E0),
      error: Color(0xFFEF5350),
      onError: charcoal,
      outline: Color(0xFF757575),
      shadow: Color(0x33000000),
      surfaceContainerHighest: Color(0xFF2A2A2A),
      onPrimaryContainer: Colors.white,
      onSecondaryContainer: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        backgroundColor: lightBlue,
        foregroundColor: charcoal,
        shadowColor: lightBlue.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightBlue,
        side: const BorderSide(color: lightBlue, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFFE0E0E0)),
      hintStyle: const TextStyle(color: Color(0xFF757575)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      selectedItemColor: lightBlue,
      unselectedItemColor: Color(0xFF757575),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      indicatorColor: lightBlue.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
              color: lightBlue, fontSize: 12, fontWeight: FontWeight.w500);
        }
        return const TextStyle(color: Color(0xFF757575), fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: lightBlue);
        }
        return const IconThemeData(color: Color(0xFF757575));
      }),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displayMedium:
          TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineLarge:
          TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      headlineMedium:
          TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      headlineSmall:
          TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Color(0xFFE0E0E0)),
      labelLarge: TextStyle(color: lightBlue, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: Color(0xFFE0E0E0)),
      labelSmall: TextStyle(color: Color(0xFF757575)),
    ),
  );
}
