import 'package:flutter/material.dart';

/// MedVault semantic color tokens.
///
/// These values define the initial neutral, content-first visual foundation.
/// They are intentionally restrained and can be refined when the final
/// product design system is established.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2962FF);
  static const Color error = Color(0xFFD32F2F);

  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1C1E);
  static const Color lightMutedText = Color(0xFF6B7075);
  static const Color lightDivider = Color(0xFFE1E4E7);

  static const Color darkBackground = Color(0xFF111315);
  static const Color darkSurface = Color(0xFF1A1D20);
  static const Color darkText = Color(0xFFE8EAED);
  static const Color darkMutedText = Color(0xFFA8ADB3);
  static const Color darkDivider = Color(0xFF30343A);
}
