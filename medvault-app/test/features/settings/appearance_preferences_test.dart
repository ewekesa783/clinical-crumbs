import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/settings/data/appearance_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppThemePreference', () {
    test('maps preferences to the correct ThemeMode', () {
      expect(AppThemePreference.system.themeMode, ThemeMode.system);
      expect(AppThemePreference.light.themeMode, ThemeMode.light);
      expect(AppThemePreference.dark.themeMode, ThemeMode.dark);
    });

    test('loads a stored theme preference', () async {
      SharedPreferences.setMockInitialValues({
        'appearance.themePreference': 'dark',
      });
      final preferences = await SharedPreferences.getInstance();

      expect(
        await loadInitialThemePreference(preferences),
        AppThemePreference.dark,
      );
    });

    test('defaults to system for missing or invalid stored values', () async {
      SharedPreferences.setMockInitialValues({});
      var preferences = await SharedPreferences.getInstance();

      expect(
        await loadInitialThemePreference(preferences),
        AppThemePreference.system,
      );

      SharedPreferences.setMockInitialValues({
        'appearance.themePreference': 'not-a-theme',
      });
      preferences = await SharedPreferences.getInstance();

      expect(
        await loadInitialThemePreference(preferences),
        AppThemePreference.system,
      );
    });
  });

  group('AppearancePreferencesController', () {
    test('persists a changed theme preference', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final controller = AppearancePreferencesController(
        preferences: preferences,
        initialPreference: AppThemePreference.system,
      );
      addTearDown(controller.dispose);

      await controller.setThemePreference(AppThemePreference.dark);

      expect(controller.state, AppThemePreference.dark);
      expect(
        preferences.getString('appearance.themePreference'),
        'dark',
      );
    });
  });

  test('settings provider can be overridden with an initialized controller',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        appearancePreferencesProvider.overrideWith(
          (ref) => AppearancePreferencesController(
            preferences: preferences,
            initialPreference: AppThemePreference.light,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(appearancePreferencesProvider),
      AppThemePreference.light,
    );
  });
}
