import 'package:flutter/material.dart';

/// [ASSUMPTION] Placeholder typography scale. No final type system has
/// been specified as of the current project state.
class AppTypography {
  AppTypography._();

  static const TextTheme textTheme = TextTheme(
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
  );
}
