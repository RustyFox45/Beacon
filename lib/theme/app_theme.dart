import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get beaconTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryMidTeal,
        primary: AppColors.primaryMidTeal,
        secondary: AppColors.accentCyan,
        tertiary: AppColors.beaconYellow,
        surface: AppColors.backgroundTint,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: AppTypography.textTheme,
      scaffoldBackgroundColor: AppColors.backgroundTint,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDarkTeal,
        surfaceTintColor: AppColors.primaryDarkTeal,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.beaconYellow,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
        iconTheme: IconThemeData(color: AppColors.beaconYellow),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDarkTeal,
          foregroundColor: AppColors.beaconYellow,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.primaryDarkTeal,
        surfaceTintColor: AppColors.primaryDarkTeal,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.1),
        thickness: 1,
      ),
    );
  }

  static ThemeData get classicTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );
  }
}
