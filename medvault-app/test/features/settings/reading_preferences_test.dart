import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/settings/data/reading_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppReadingTextSize', () {
    test('provides the expected reading scale factors', () {
      expect(AppReadingTextSize.small.scale, 0.9);
      expect(AppReadingTextSize.normal.scale, 1.0);
      expect(AppReadingTextSize.large.scale, 1.3);
      expect(AppReadingTextSize.extraLarge.scale, 1.6);
    });

    test('defaults to Normal when no valid preference is stored', () async {
      SharedPreferences.setMockInitialValues({});
      var preferences = await SharedPreferences.getInstance();

      expect(
        await loadInitialReadingTextSize(preferences),
        AppReadingTextSize.normal,
      );

      SharedPreferences.setMockInitialValues({
        'reading.textSize': 'invalid',
      });
      preferences = await SharedPreferences.getInstance();

      expect(
        await loadInitialReadingTextSize(preferences),
        AppReadingTextSize.normal,
      );
    });

    test('loads a saved reading size', () async {
      SharedPreferences.setMockInitialValues({
        'reading.textSize': 'large',
      });
      final preferences = await SharedPreferences.getInstance();

      expect(
        await loadInitialReadingTextSize(preferences),
        AppReadingTextSize.large,
      );
    });
  });

  test('loads a saved Extra large reading size', () async {
    SharedPreferences.setMockInitialValues({
      'reading.textSize': 'extraLarge',
    });
    final preferences = await SharedPreferences.getInstance();
    expect(
      await loadInitialReadingTextSize(preferences),
      AppReadingTextSize.extraLarge,
    );
  });

  test('controller persists a changed reading size', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = ReadingPreferencesController(
      preferences: preferences,
      initialSize: AppReadingTextSize.normal,
    );
    addTearDown(controller.dispose);

    await controller.setTextSize(AppReadingTextSize.large);

    expect(controller.state, AppReadingTextSize.large);
    expect(preferences.getString('reading.textSize'), 'large');
  });
}
