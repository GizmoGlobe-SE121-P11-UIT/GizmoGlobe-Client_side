// This file contains the main theme data for the app. Use AppTheme.lightTheme and AppTheme.darkTheme in MaterialApp.
import 'package:flutter/material.dart';

class AppTheme {
  // Define the blue color palette
  static const Color primaryBlue = Color(0xFF1565C0); // Main blue
  static const Color lightBlue = Color(0xFF42A5F5); // Lighter blue
  static const Color darkBlue = Color(0xFF0D47A1); // Darker blue
  static const Color accentBlue = Color(0xFF2196F3); // Accent blue

  // Monochrome grays - refined for better contrast
  static const Color offWhite =
      Color(0xFFF8F9FA); // Subtle off-white background
  static const Color lightGray =
      Color(0xFFF1F3F4); // Slightly darker for cards on off-white
  static const Color mediumGray = Color(0xFF9E9E9E);
  static const Color darkGray = Color(0xFF424242);
  static const Color charcoal = Color(0xFF212121);

  // Dark mode surface hierarchy - increased contrast for better UX
  static const Color darkBackground = Color(0xFF121212); // Darkest - scaffold
  static const Color darkSurface = Color(0xFF1A1A1A); // Dark - main surfaces
  static const Color darkCard =
      Color(0xFF2D2D2D); // Notably lighter - cards stand out
  static const Color darkContainer =
      Color(0xFF363636); // Lightest - containers/inputs

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
      surface: offWhite,
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
    scaffoldBackgroundColor: offWhite,
    appBarTheme: AppBarTheme(
      backgroundColor: offWhite,
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
    cardTheme: CardThemeData(
      color: Colors.white, // Pure white cards stand out on off-white background
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
      backgroundColor: offWhite,
      selectedItemColor: primaryBlue,
      unselectedItemColor: mediumGray,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          color: charcoal, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      displayMedium: TextStyle(
          color: charcoal, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      displaySmall: TextStyle(
          color: charcoal, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      headlineLarge: TextStyle(
          color: charcoal, fontWeight: FontWeight.w600, fontFamily: 'Roboto'),
      headlineMedium: TextStyle(
          color: charcoal, fontWeight: FontWeight.w600, fontFamily: 'Roboto'),
      headlineSmall: TextStyle(
          color: charcoal, fontWeight: FontWeight.w600, fontFamily: 'Roboto'),
      titleLarge: TextStyle(
          color: charcoal, fontWeight: FontWeight.w600, fontFamily: 'Roboto'),
      titleMedium: TextStyle(
          color: charcoal, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      titleSmall: TextStyle(
          color: charcoal, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      bodyLarge: TextStyle(color: charcoal, fontFamily: 'Roboto'),
      bodyMedium: TextStyle(color: charcoal, fontFamily: 'Roboto'),
      bodySmall: TextStyle(color: darkGray, fontFamily: 'Roboto'),
      labelLarge: TextStyle(
          color: primaryBlue,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto'),
      labelMedium: TextStyle(color: darkGray, fontFamily: 'Roboto'),
      labelSmall: TextStyle(color: mediumGray, fontFamily: 'Roboto'),
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
      surface: darkSurface,
      onSurface: Colors.white,
      onSurfaceVariant: Color(0xFFE0E0E0),
      error: Color(0xFFEF5350),
      onError: charcoal,
      outline: Color(0xFF757575),
      shadow: Color(0x33000000),
      surfaceContainerHighest: darkContainer,
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
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
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
    cardTheme: CardThemeData(
      color: darkCard, // Elevated cards are lighter than surface
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkContainer,
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
      backgroundColor: darkSurface,
      selectedItemColor: lightBlue,
      unselectedItemColor: Color(0xFF757575),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
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
      displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto'),
      displayMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto'),
      displaySmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto'),
      headlineLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto'),
      headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto'),
      headlineSmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto'),
      titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto'),
      titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto'),
      titleSmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto'),
      bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
      bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
      bodySmall: TextStyle(color: Color(0xFFE0E0E0), fontFamily: 'Roboto'),
      labelLarge: TextStyle(
          color: lightBlue, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
      labelMedium: TextStyle(color: Color(0xFFE0E0E0), fontFamily: 'Roboto'),
      labelSmall: TextStyle(color: Color(0xFF757575), fontFamily: 'Roboto'),
    ),
  );
}
