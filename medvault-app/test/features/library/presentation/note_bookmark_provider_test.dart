import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/di/injector.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/domain/entities/bookmark.dart';
import 'package:medvault_app/features/library/domain/entities/citation.dart';
import 'package:medvault_app/features/library/domain/entities/history.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';
import 'package:medvault_app/features/library/domain/repositories/bookmark_repository.dart';
import 'package:medvault_app/features/library/domain/repositories/citation_repository.dart';
import 'package:medvault_app/features/library/domain/repositories/history_repository.dart';
import 'package:medvault_app/features/library/domain/repositories/note_repository.dart';
import 'package:medvault_app/features/library/domain/repositories/taxonomy_repository.dart';
import 'package:medvault_app/features/library/domain/services/library_service.dart';
import 'package:medvault_app/features/library/presentation/providers/note_bookmark_provider.dart';

class _FakeLibraryService extends LibraryService {
  _FakeLibraryService({required this.initiallyBookmarked})
      : super(
          taxonomyRepository: _FakeTaxonomyRepository(),
          noteRepository: _FakeNoteRepository(),
          citationRepository: _FakeCitationRepository(),
          bookmarkRepository: _FakeBookmarkRepository(),
          historyRepository: _FakeHistoryRepository(),
          generateUuid: () => 'generated-bookmark',
          createSyncMetadata: _sync,
          now: () => DateTime.utc(2026, 1, 1),
        );

  final bool initiallyBookmarked;
  Object? bookmarkError;
  int bookmarkCalls = 0;
  int unbookmarkCalls = 0;
  Object? unbookmarkError;
  String? bookmarkedNoteUuid;

  @override
  Future<bool> isNoteBookmarked(String noteUuid) async => initiallyBookmarked;

  @override
  Future<Bookmark> bookmarkNote(String noteUuid, {String? label}) async {
    bookmarkCalls++;
    bookmarkedNoteUuid = noteUuid;
    if (bookmarkError != null) throw bookmarkError!;
    return Bookmark(
      uuid: 'generated-bookmark',
      noteUuid: noteUuid,
      label: label,
      createdAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );
  }

  @override
  Future<void> unbookmarkNote(String noteUuid) async {
    unbookmarkCalls++;
    if (unbookmarkError != null) throw unbookmarkError!;
  }
}

class _FakeTaxonomyRepository implements TaxonomyRepository {
  @override
  Future<void> save(TaxonomyNode node) async {}
  @override
  Future<TaxonomyNode?> getByUuid(String uuid) async => null;
  @override
  Future<List<TaxonomyNode>> getChildren(String parentUuid) async => [];
  @override
  Future<List<TaxonomyNode>> getAll() async => [];
}

class _FakeNoteRepository implements NoteRepository {
  @override
  Future<void> save(Note note) async {}
  @override
  Future<Note?> getByUuid(String uuid) async => null;
  @override
  Future<Note?> getByTopicAndMode(String topicUuid, Mode mode) async => null;
  @override
  @override
  Future<List<Note>> getAll() async => [];

  Future<List<Note>> search(String query) async => [];
}

class _FakeCitationRepository implements CitationRepository {
  @override
  Future<void> save(Citation citation) async {}
  @override
  Future<Citation?> getByUuid(String uuid) async => null;
  @override
  Future<List<Citation>> getByUuids(List<String> uuids) async => [];
}

class _FakeBookmarkRepository implements BookmarkRepository {
  @override
  Future<void> save(Bookmark bookmark) async {}
  @override
  Future<Bookmark?> getByUuid(String uuid) async => null;

  @override
  Future<void> deleteByNoteUuid(String noteUuid) async {}
  @override
  Future<List<Bookmark>> getByNoteUuid(String noteUuid) async => [];

  @override
  Future<List<Bookmark>> getRecent({int limit = 10}) async => [];
}

class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<void> save(History history) async {}
  @override
  Future<History?> getByUuid(String uuid) async => null;
  @override
  Future<History?> getByNoteUuid(String noteUuid) async => null;

  @override
  Future<List<History>> getRecent({int? limit = 10}) async => [];
}

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'test-device',
      syncRevision: 1,
    );

ProviderContainer _containerWith(_FakeLibraryService service) =>
    ProviderContainer(
      overrides: [
        libraryServiceProvider.overrideWith((ref) async => service),
      ],
    );

void main() {
  test('loads the initial bookmark state from the service', () async {
    final service = _FakeLibraryService(initiallyBookmarked: true);
    final container = _containerWith(service);
    addTearDown(container.dispose);

    final result = await container.read(noteBookmarkProvider('note-1').future);

    expect(result, isTrue);
  });

  test('toggles an unbookmarked note on successfully', () async {
    final service = _FakeLibraryService(initiallyBookmarked: false);
    final container = _containerWith(service);
    addTearDown(container.dispose);
    final provider = noteBookmarkProvider('note-1');

    expect(await container.read(provider.future), isFalse);

    await container.read(provider.notifier).toggle();

    expect(service.bookmarkCalls, 1);
    expect(service.bookmarkedNoteUuid, 'note-1');
    expect(container.read(provider), const AsyncData<bool>(true));
  });

  test('preserves the unbookmarked state when saving fails', () async {
    final error = StateError('Bookmark save failed');
    final service = _FakeLibraryService(initiallyBookmarked: false)
      ..bookmarkError = error;
    final container = _containerWith(service);
    addTearDown(container.dispose);
    final provider = noteBookmarkProvider('note-1');

    expect(await container.read(provider.future), isFalse);

    await expectLater(
      container.read(provider.notifier).toggle(),
      throwsA(same(error)),
    );

    expect(service.bookmarkCalls, 1);
    expect(container.read(provider), const AsyncData<bool>(false));
  });
}
