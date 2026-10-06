import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/bootstrap.dart';
import '../../features/library/data/repositories/isar_bookmark_repository.dart';
import '../../features/library/data/repositories/isar_citation_repository.dart';
import '../../features/library/data/repositories/isar_history_repository.dart';
import '../../features/library/data/repositories/isar_note_repository.dart';
import '../../features/library/data/repositories/isar_taxonomy_repository.dart';
import '../../features/library/domain/repositories/taxonomy_repository.dart';
import '../../features/library/domain/services/taxonomy_navigation_service.dart';
import '../../features/library/domain/repositories/bookmark_repository.dart';
import '../../features/library/domain/repositories/citation_repository.dart';
import '../../features/library/domain/repositories/history_repository.dart';
import '../../features/library/domain/repositories/note_repository.dart';

part 'injector.g.dart';

/// Provides the application's single Isar database instance.
@Riverpod(keepAlive: true)
Future<Isar> appDatabase(AppDatabaseRef ref) async {
  return bootstrap();
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
