import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0A0A), // Darker background matching screenshots
    primaryColor: const Color(0xFF4CAF50), // Green accent from text
    
    // Card & Dialog colors
    cardColor: const Color(0xFF1A1A1A),
    dialogBackgroundColor: const Color(0xFF1A1A1A),
    
    // Custom color scheme
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4CAF50),      // Green accent from text
      secondary: Color(0xFF5D4EE6),     // Purple from breathing exercise button
      surface: Color(0xFF1A1A1A),       // Card background
      background: Color(0xFF0A0A0A),    // App background
      error: Color(0xFFCF6679),         // Keeping error red
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),
    
    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0A0A),
      elevation: 0,
    ),
    
    // Card theme
    cardTheme: CardTheme(
      color: const Color(0xFF1A1A1A),
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
      backgroundColor: const Color(0xFF1A1A1A),
      indicatorColor: const Color(0xFF5D4EE6).withOpacity(0.2),
      iconTheme: MaterialStateProperty.all(
        const IconThemeData(color: Colors.white70),
      ),
    ),

    // Additional colors for charts and visualizations
    extensions: [
      CustomColors(
        chartColors: [
          const Color(0xFFFF6B4A),  // Orange from chart
          const Color(0xFF5D4EE6),  // Purple from chart
          const Color(0xFF4CAF50),  // Green accent
          const Color(0xFFE64E4E),  // Red from chart
        ],
      ),
    ],
  );
}

// Custom extension to handle chart colors
class CustomColors extends ThemeExtension<CustomColors> {
  final List<Color> chartColors;

  const CustomColors({
    required this.chartColors,
  });

  @override
  ThemeExtension<CustomColors> copyWith({
    List<Color>? chartColors,
  }) {
    return CustomColors(
      chartColors: chartColors ?? this.chartColors,
    );
  }

  @override
  ThemeExtension<CustomColors> lerp(
    ThemeExtension<CustomColors>? other,
    double t,
  ) {
    if (other is! CustomColors) {
      return this;
    }
    return this;
  }
}