import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: const Color(0xFF6B4EE6),
    
    // Card & Dialog colors
    cardColor: const Color(0xFF1E1E1E),
    dialogBackgroundColor: const Color(0xFF1E1E1E),
    
    // Custom color scheme
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6B4EE6),      // Purple accent
      secondary: Color(0xFF4A4458),     // Muted purple
      surface: Color(0xFF1E1E1E),       // Card background
      background: Color(0xFF121212),    // App background
      error: Color(0xFFCF6679),         // Error red
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),
    
    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
    ),
    
    // Card theme
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // Text theme
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        color: Colors.white70,
      ),
    ),
    
    // Navigation bar theme
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      indicatorColor: const Color(0xFF6B4EE6).withOpacity(0.2),
      iconTheme: MaterialStateProperty.all(
        const IconThemeData(color: Colors.white70),
      ),
    ),
  );
}