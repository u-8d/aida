import 'package:flutter/material.dart';

class AppTheme {
  // Modern color palette: muted blues/grays with orange/red accents
  static const Color primaryBlue = Color(0xFF4A6FA5);        // Muted blue
  static const Color lightBlue = Color(0xFF8FA4C7);          // Light muted blue
  static const Color darkBlue = Color(0xFF2C4B73);           // Dark muted blue
  
  static const Color neutralGray = Color(0xFF6B7280);        // Muted gray
  static const Color lightGray = Color(0xFFF3F4F6);          // Very light gray
  static const Color darkGray = Color(0xFF374151);           // Dark gray
  
  static const Color accentOrange = Color(0xFFFF8C42);       // Bright orange
  static const Color urgentRed = Color(0xFFEF4444);          // Bright red
  static const Color successGreen = Color(0xFF10B981);       // Success green
  static const Color warningAmber = Color(0xFFF59E0B);       // Warning amber
  
  // Disaster zone specific colors
  static const Color disasterZoneRed = Color(0xFFDC2626);    // Red overlay
  static const Color priorityFlash = Color(0xFFEF4444);      // Lightning bolt
  static const Color campaignProgress = Color(0xFFFF8C42);   // Progress orange
  
  // Background gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, lightBlue],
  );
  
  static const LinearGradient neutralGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightGray, Colors.white],
  );
  
  static const LinearGradient urgentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [urgentRed, Color(0xFFDC2626)],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: accentOrange,
        error: urgentRed,
        surface: lightGray,
        onSurface: darkGray,
      ),
      useMaterial3: true,
      
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: primaryBlue.withOpacity(0.1),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: lightGray,
        selectedColor: accentOrange.withOpacity(0.2),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryBlue,
        unselectedItemColor: neutralGray,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkGray,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkGray,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkGray,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: darkGray,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: neutralGray,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: neutralGray,
        ),
      ),
    );
  }
  
  // Custom components styles
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: primaryBlue.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration get disasterZoneDecoration => BoxDecoration(
    color: disasterZoneRed.withOpacity(0.15),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: disasterZoneRed.withOpacity(0.3),
      width: 2,
    ),
  );
  
  static BoxDecoration get progressDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        campaignProgress,
        campaignProgress.withOpacity(0.8),
      ],
    ),
    borderRadius: BorderRadius.circular(12),
  );
  
  static TextStyle get urgentTextStyle => const TextStyle(
    color: urgentRed,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
  
  static TextStyle get successTextStyle => const TextStyle(
    color: successGreen,
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );
}
