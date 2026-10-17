import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppReadingTextSize {
  small,
  normal,
  large,
  extraLarge;

  String get label {
    switch (this) {
      case AppReadingTextSize.small:
        return 'Small';
      case AppReadingTextSize.normal:
        return 'Normal';
      case AppReadingTextSize.large:
        return 'Large';
      case AppReadingTextSize.extraLarge:
        return 'Extra large';
    }
  }

  String get description {
    switch (this) {
      case AppReadingTextSize.small:
        return 'More text on the screen';
      case AppReadingTextSize.normal:
        return 'Balanced reading size';
      case AppReadingTextSize.large:
        return 'Larger text for easier reading';
      case AppReadingTextSize.extraLarge:
        return 'Maximum text size for relaxed reading';
    }
  }

  double get scale {
    switch (this) {
      case AppReadingTextSize.small:
        return 0.9;
      case AppReadingTextSize.normal:
        return 1.0;
      case AppReadingTextSize.large:
        return 1.3;
      case AppReadingTextSize.extraLarge:
        return 1.6;
    }
  }

  static AppReadingTextSize fromStoredValue(String? value) {
    return AppReadingTextSize.values.firstWhere(
      (size) => size.name == value,
      orElse: () => AppReadingTextSize.normal,
    );
  }
}

class ReadingPreferencesController extends StateNotifier<AppReadingTextSize> {
  ReadingPreferencesController({
    required SharedPreferences preferences,
    required AppReadingTextSize initialSize,
  })  : _preferences = preferences,
        super(initialSize);

  static const String _textSizeKey = 'reading.textSize';

  final SharedPreferences _preferences;

  Future<void> setTextSize(AppReadingTextSize size) async {
    final previousSize = state;
    state = size;

    try {
      final saved = await _preferences.setString(_textSizeKey, size.name);
      if (!saved) {
        state = previousSize;
      }
    } catch (_) {
      state = previousSize;
      rethrow;
    }
  }
}

final readingPreferencesProvider =
    StateNotifierProvider<ReadingPreferencesController, AppReadingTextSize>(
  (ref) => throw UnimplementedError(
    'Reading preferences must be initialized before the app starts.',
  ),
);

Future<AppReadingTextSize> loadInitialReadingTextSize(
  SharedPreferences preferences,
) async {
  return AppReadingTextSize.fromStoredValue(
    preferences.getString('reading.textSize'),
  );
}
