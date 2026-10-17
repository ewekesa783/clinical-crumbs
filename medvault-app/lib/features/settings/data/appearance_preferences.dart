import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference {
  system,
  light,
  dark;

  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.system:
        return ThemeMode.system;
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  String get label {
    switch (this) {
      case AppThemePreference.system:
        return 'System default';
      case AppThemePreference.light:
        return 'Light';
      case AppThemePreference.dark:
        return 'Dark';
    }
  }

  static AppThemePreference fromStoredValue(String? value) {
    return AppThemePreference.values.firstWhere(
      (preference) => preference.name == value,
      orElse: () => AppThemePreference.system,
    );
  }
}

class AppearancePreferencesController
    extends StateNotifier<AppThemePreference> {
  AppearancePreferencesController({
    required SharedPreferences preferences,
    required AppThemePreference initialPreference,
  })  : _preferences = preferences,
        super(initialPreference);

  static const String _themeKey = 'appearance.themePreference';

  final SharedPreferences _preferences;

  Future<void> setThemePreference(AppThemePreference preference) async {
    final previousPreference = state;
    state = preference;

    try {
      final saved = await _preferences.setString(
        _themeKey,
        preference.name,
      );

      if (!saved) {
        state = previousPreference;
      }
    } catch (_) {
      state = previousPreference;
      rethrow;
    }
  }
}

final appearancePreferencesProvider = StateNotifierProvider<
    AppearancePreferencesController, AppThemePreference>(
  (ref) => throw UnimplementedError(
    'Appearance preferences must be initialized before the app starts.',
  ),
);

Future<AppThemePreference> loadInitialThemePreference(
  SharedPreferences preferences,
) async {
  return AppThemePreference.fromStoredValue(
    preferences.getString('appearance.themePreference'),
  );
}
