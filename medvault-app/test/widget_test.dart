import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/app/app.dart';
import 'package:medvault_app/features/settings/data/appearance_preferences.dart';
import 'package:medvault_app/features/settings/data/reading_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MedVault app shell renders', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appearancePreferencesProvider.overrideWith(
            (ref) => AppearancePreferencesController(
              preferences: preferences,
              initialPreference: AppThemePreference.system,
            ),
          ),
          readingPreferencesProvider.overrideWith(
            (ref) => ReadingPreferencesController(
              preferences: preferences,
              initialSize: AppReadingTextSize.normal,
            ),
          ),
        ],
        child: const MedVaultApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
