import 'package:flutter/material.dart';

class AppColors {
  // Dark Teal (Background color from the provided palette)
  static const Color primaryDarkTeal = Color(0xFF0C5974);
  
  // Mid Teal (A slightly lighter shade for gradients and accents)
  static const Color primaryMidTeal = Color(0xFF1582A4);
  
  // Bright Cyan (High energy accent color)
  static const Color accentCyan = Color(0xFF0EB7D2);
  
  // Light Blue (Soft background or secondary accent)
  static const Color accentLightBlue = Color(0xFF8ED6E8);
  
  // Beacon Yellow (Iconography and branding typography color)
  static const Color beaconYellow = Color(0xFFF4D010);
  
  // Neutral Charcoal Gray (Neutrals for text and borders)
  static const Color neutralCharcoal = Color(0xFF4D5459);

  // Subtle Background Tint (5% Cyan/Light Blue for a softened look)
  static const Color backgroundTint = Color(0xFFF7FDFE);

  // Typography aliases (used by AppTypography)
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4D5459);

  // Destructive / Error Red (warm red for delete actions)
  static const Color destructiveRed = Color(0xFFD94040);

  // Gradient definitions for easy reuse
  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryMidTeal, primaryDarkTeal],
  );

  static const LinearGradient drawerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryMidTeal, primaryDarkTeal],
  );
}
