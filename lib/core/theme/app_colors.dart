import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - minimalist blue palette
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF0D47A1);
  
  // Background colors - clean and simple
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
  // Text colors - high contrast for readability (WCAG AA compliant)
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF5A5A5A); // Improved contrast for accessibility
  static const Color textTertiary = Color(0xFF757575);  // Improved from #9E9E9E
  static const Color textWhite = Colors.white;
  
  // UI elements
  static const Color cardBackground = Colors.white;
  static const Color inputFill = Colors.white;
  static const Color inputBorder = Color(0xFFBDBDBD);
  static const Color inputBorderFocused = Color(0xFF1976D2);
  static const Color inputBorderError = Color(0xFFF44336);
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocused = Color(0xFF1976D2);
  static const Color placeholder = Color(0xFF9E9E9E);
  
  // Status colors - more communicative
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E8);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
  
  // Specific component colors (keeping existing functionality)
  static const Color exitTypeNorandino = Color(0xFF4CAF50);
  static const Color exitTypeAutoconsumo = Color(0xFF8D6E63);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color backButtonRed = Color(0xFFF44336);
  
  // Deprecated - keeping for backward compatibility
  static const Color backgroundBrown = Color(0xFF8B5A2B);
  
  // Simple opacity variants
  static Color cardBackgroundTransparent = Colors.white.withValues(alpha: 0.95);
  static Color labelTransparent = Colors.white.withValues(alpha: 0.8);
}