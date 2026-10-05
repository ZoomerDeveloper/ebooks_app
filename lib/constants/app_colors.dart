import 'package:flutter/material.dart';

class AppColors {
  static const Color white = Color(0xFFFFFFFF);

  // Primary Colors - Modern gradient scheme
  static const Color primary = Color(0xFF840C0C); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);

  // Secondary Colors
  static const Color secondary = Color(0xFFF65C5C); // Purple
  static const Color secondaryDark = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);

  // Accent Colors
  static const Color accent = Color(0xFFEC4899); // Pink
  static const Color accentLight = Color(0xFFF472B6);

  // Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color cardBackground = Colors.white;
  static const Color cardBackgroundDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textWhite = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [secondary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
