import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/di/injector.dart';
import 'features/settings/data/appearance_preferences.dart';
import 'features/settings/data/reading_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final AppThemePreference initialTheme =
      await loadInitialThemePreference(preferences);
  final AppReadingTextSize initialReadingSize =
      await loadInitialReadingTextSize(preferences);

  final Isar isar = await bootstrap();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) async => isar),
        appearancePreferencesProvider.overrideWith(
          (ref) => AppearancePreferencesController(
            preferences: preferences,
            initialPreference: initialTheme,
          ),
        ),
        readingPreferencesProvider.overrideWith(
          (ref) => ReadingPreferencesController(
            preferences: preferences,
            initialSize: initialReadingSize,
          ),
        ),
      ],
      child: const MedVaultApp(),
    ),
  );
}
