import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/startup_screen.dart';
import 'core/di/injector.dart';
import 'features/settings/data/appearance_preferences.dart';
import 'features/settings/data/reading_preferences.dart';
import 'features/library/data/bootstrap/starter_library_initializer.dart';
import 'features/library/data/seed/initial_taxonomy_seeder.dart';
import 'features/library/data/seed/initial_taxonomy_subunit_seeder.dart';
import 'features/library/data/seed/initial_taxonomy_topic_seeder.dart';
import 'features/library/data/repositories/isar_taxonomy_repository.dart';
import 'features/library/data/repositories/full_library_backup_recovery_service.dart';
import 'core/utils/uuid_generator.dart';
import 'core/time/clock.dart';
import 'core/sync/sync_metadata_factory.dart';
import 'core/storage/isar_device_identity_repository.dart';
import 'core/storage/learning_resource_file_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialization = _initializeStartup();
  final minimumVisibleDuration = Future<void>.delayed(
    const Duration(milliseconds: 1500),
  );

  runApp(
    ClinicalCrumbsStartupGate(
      initialization: initialization,
      minimumVisibleDuration: minimumVisibleDuration,
    ),
  );
}

Future<_StartupData> _initializeStartup() async {
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final Isar isar = await bootstrap();

  // Recover an interrupted restore before any initializer or seeder can
  // mutate the recovered state. Errors intentionally stop startup.
  await FullLibraryBackupRecoveryService(
    isar: isar,
    preferences: preferences,
  ).recoverIfPending();

  // Read preferences after recovery so the first frame uses restored values.
  final AppThemePreference initialTheme =
      await loadInitialThemePreference(preferences);
  final AppReadingTextSize initialReadingSize =
      await loadInitialReadingTextSize(preferences);

  // Keep installation identity separate from restored library data.
  const clock = SystemClock();
  final identityRepository = IsarDeviceIdentityRepository(
    isar,
    generateUuid: UuidGenerator().call,
  );
  final deviceIdentity = await identityRepository.getOrCreate();

  // A restored full snapshot is authoritative: do not append bundled starter
  // content or seed taxonomy over it on subsequent launches.
  final hasRestoredSnapshot = preferences.getBool(
        'clinical_crumbs_full_library_snapshot_active',
      ) ??
      false;

  if (!hasRestoredSnapshot) {
    await StarterLibraryInitializer(
      isar: isar,
      fileStorage: LearningResourceFileStorage(),
      preferences: preferences,
      createSyncMetadata: SyncMetadataFactory(
        deviceIdentity: deviceIdentity,
        clock: clock,
      ).call,
      now: clock.now,
    ).initializeIfEligible();

    await StarterLibraryInitializer(
      isar: isar,
      fileStorage: LearningResourceFileStorage(),
      preferences: preferences,
      createSyncMetadata: SyncMetadataFactory(
        deviceIdentity: deviceIdentity,
        clock: clock,
      ).call,
      now: clock.now,
    ).updateBundledContent();

    final taxonomyRepository = IsarTaxonomyRepository(isar);

    await InitialTaxonomySeeder(
      taxonomyRepository: taxonomyRepository,
      syncMetadataFactory: SyncMetadataFactory(
        deviceIdentity: deviceIdentity,
        clock: clock,
      ),
      clock: clock,
    ).seed();
    await InitialTaxonomySubunitSeeder(
      taxonomyRepository: taxonomyRepository,
      syncMetadataFactory: SyncMetadataFactory(
        deviceIdentity: deviceIdentity,
        clock: clock,
      ),
      clock: clock,
    ).seed();
    await InitialTaxonomyTopicSeeder(
      taxonomyRepository: taxonomyRepository,
      syncMetadataFactory: SyncMetadataFactory(
        deviceIdentity: deviceIdentity,
        clock: clock,
      ),
      clock: clock,
    ).seed();
  }

  return _StartupData(
    isar: isar,
    preferences: preferences,
    initialTheme: initialTheme,
    initialReadingSize: initialReadingSize,
  );
}

class ClinicalCrumbsStartupGate extends StatelessWidget {
  const ClinicalCrumbsStartupGate({
    required this.initialization,
    required this.minimumVisibleDuration,
    super.key,
  });

  // ignore: library_private_types_in_public_api
  final Future<_StartupData> initialization;
  final Future<void> minimumVisibleDuration;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: minimumVisibleDuration,
      builder: (context, durationSnapshot) {
        if (durationSnapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: ClinicalCrumbsStartupScreen(),
          );
        }

        return FutureBuilder<_StartupData>(
          future: initialization,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: ClinicalCrumbsStartupScreen(
                  errorMessage: snapshot.error.toString(),
                ),
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: ClinicalCrumbsStartupScreen(),
              );
            }

            return ProviderScope(
              overrides: [
                appDatabaseProvider.overrideWith((ref) async => data.isar),
                appearancePreferencesProvider.overrideWith(
                  (ref) => AppearancePreferencesController(
                    preferences: data.preferences,
                    initialPreference: data.initialTheme,
                  ),
                ),
                readingPreferencesProvider.overrideWith(
                  (ref) => ReadingPreferencesController(
                    preferences: data.preferences,
                    initialSize: data.initialReadingSize,
                  ),
                ),
              ],
              child: const MedVaultApp(),
            );
          },
        );
      },
    );
  }
}

class _StartupData {
  const _StartupData({
    required this.isar,
    required this.preferences,
    required this.initialTheme,
    required this.initialReadingSize,
  });

  final Isar isar;
  final SharedPreferences preferences;
  final AppThemePreference initialTheme;
  final AppReadingTextSize initialReadingSize;
}
