import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/bootstrap.dart';
import '../utils/uuid_generator.dart';
import '../time/clock.dart';
import '../sync/sync_metadata_factory.dart';
import '../storage/isar_device_identity_repository.dart';
import '../storage/device_identity_repository.dart';
import '../storage/learning_resource_file_storage.dart';
import '../../features/library/data/repositories/isar_bookmark_repository.dart';
import '../../features/library/data/repositories/isar_citation_repository.dart';
import '../../features/library/data/repositories/isar_history_repository.dart';
import '../../features/library/data/repositories/isar_learning_resource_repository.dart';
import '../../features/library/data/repositories/isar_note_repository.dart';
import '../../features/library/data/repositories/isar_taxonomy_repository.dart';
import '../../features/library/domain/repositories/taxonomy_repository.dart';
import '../../features/library/domain/services/taxonomy_navigation_service.dart';
import '../../features/library/domain/services/library_service.dart';
import '../../features/library/domain/repositories/bookmark_repository.dart';
import '../../features/library/domain/repositories/citation_repository.dart';
import '../../features/library/domain/repositories/history_repository.dart';
import '../../features/library/domain/repositories/learning_resource_repository.dart';
import '../../features/library/domain/repositories/note_repository.dart';

part 'injector.g.dart';

/// Provides the application's single Isar database instance.
@Riverpod(keepAlive: true)
Future<Isar> appDatabase(AppDatabaseRef ref) async {
  return bootstrap();
}

/// Provides the application's clock.
@Riverpod(keepAlive: true)
Clock clock(ClockRef ref) {
  return const SystemClock();
}

/// Provides managed local storage for imported learning-resource files.
@riverpod
LearningResourceFileStorage learningResourceFileStorage(
  LearningResourceFileStorageRef ref,
) {
  return LearningResourceFileStorage();
}

/// Provides the persistent identity of this MedVault installation.
@riverpod
Future<DeviceIdentityRepository> deviceIdentityRepository(
  DeviceIdentityRepositoryRef ref,
) async {
  final isar = await ref.watch(appDatabaseProvider.future);
  final uuidGenerator = UuidGenerator();
  return IsarDeviceIdentityRepository(
    isar,
    generateUuid: uuidGenerator.call,
  );
}

/// Provides the factory for initial synchronization metadata.
@riverpod
Future<SyncMetadataFactory> syncMetadataFactory(
  SyncMetadataFactoryRef ref,
) async {
  final deviceIdentityRepository =
      await ref.watch(deviceIdentityRepositoryProvider.future);
  final deviceIdentity = await deviceIdentityRepository.getOrCreate();
  final clock = ref.watch(clockProvider);

  return SyncMetadataFactory(
    deviceIdentity: deviceIdentity,
    clock: clock,
  );
}

/// Provides the production LibraryService with all required repositories and infrastructure dependencies.
@riverpod
Future<LibraryService> libraryService(LibraryServiceRef ref) async {
  final taxonomyRepository = await ref.watch(taxonomyRepositoryProvider.future);
  final noteRepository = await ref.watch(noteRepositoryProvider.future);
  final citationRepository = await ref.watch(citationRepositoryProvider.future);
  final bookmarkRepository = await ref.watch(bookmarkRepositoryProvider.future);
  final historyRepository = await ref.watch(historyRepositoryProvider.future);
  final learningResourceRepository =
      await ref.watch(learningResourceRepositoryProvider.future);
  final syncMetadataFactory =
      await ref.watch(syncMetadataFactoryProvider.future);
  final clock = ref.watch(clockProvider);
  final uuidGenerator = UuidGenerator();

  return LibraryService(
    taxonomyRepository: taxonomyRepository,
    noteRepository: noteRepository,
    citationRepository: citationRepository,
    bookmarkRepository: bookmarkRepository,
    historyRepository: historyRepository,
    learningResourceRepository: learningResourceRepository,
    generateUuid: uuidGenerator.call,
    createSyncMetadata: syncMetadataFactory.call,
    now: clock.now,
  );
}

/// Provides the taxonomy repository backed by the application's Isar database.
@riverpod
Future<TaxonomyRepository> taxonomyRepository(TaxonomyRepositoryRef ref) async {
  final isar = await ref.watch(appDatabaseProvider.future);
  return IsarTaxonomyRepository(isar);
}

/// Provides the note repository backed by the application's Isar database.
@riverpod
Future<NoteRepository> noteRepository(NoteRepositoryRef ref) async {
  final isar = await ref.watch(appDatabaseProvider.future);
  return IsarNoteRepository(isar);
}

/// Provides the citation repository backed by the application's Isar database.
@riverpod
Future<CitationRepository> citationRepository(
  CitationRepositoryRef ref,
) async {
  final isar = await ref.watch(appDatabaseProvider.future);
  return IsarCitationRepository(isar);
}

/// Provides the bookmark repository backed by the application's Isar database.
@riverpod
Future<BookmarkRepository> bookmarkRepository(
  BookmarkRepositoryRef ref,
) async {
  final isar = await ref.watch(appDatabaseProvider.future);
  return IsarBookmarkRepository(isar);
}

/// Provides the learning-resource repository backed by the application's Isar database.
@riverpod
Future<LearningResourceRepository> learningResourceRepository(
  LearningResourceRepositoryRef ref,
) async {
  final isar = await ref.watch(appDatabaseProvider.future);
  return IsarLearningResourceRepository(isar);
}

/// Provides the history repository backed by the application's Isar database.
@riverpod
Future<HistoryRepository> historyRepository(
  HistoryRepositoryRef ref,
) async {
  final isar = await ref.watch(appDatabaseProvider.future);
  return IsarHistoryRepository(isar);
}

/// Provides the taxonomy navigation service backed by the application's
/// taxonomy repository.
@riverpod
Future<TaxonomyNavigationService> taxonomyNavigationService(
  TaxonomyNavigationServiceRef ref,
) async {
  final taxonomyRepository = await ref.watch(taxonomyRepositoryProvider.future);
  return TaxonomyNavigationService(taxonomyRepository: taxonomyRepository);
}
