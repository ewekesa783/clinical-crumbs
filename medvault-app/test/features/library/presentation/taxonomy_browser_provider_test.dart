import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';
import 'package:medvault_app/features/library/domain/entities/bookmark.dart';
import 'package:medvault_app/features/library/domain/entities/citation.dart';
import 'package:medvault_app/features/library/domain/entities/history.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
import 'package:medvault_app/features/library/domain/repositories/bookmark_repository.dart';
import 'package:medvault_app/features/library/domain/repositories/citation_repository.dart';
import 'package:medvault_app/features/library/domain/repositories/history_repository.dart';
import 'package:medvault_app/features/library/domain/repositories/note_repository.dart';
import 'package:medvault_app/features/library/domain/services/dto/topic_notes.dart';
import 'package:medvault_app/features/library/domain/services/library_service.dart';
import 'package:medvault_app/features/library/domain/services/taxonomy_navigation_service.dart';
import 'package:medvault_app/features/library/domain/repositories/taxonomy_repository.dart';
import 'package:medvault_app/core/di/injector.dart';
import 'package:medvault_app/features/library/presentation/providers/taxonomy_browser_provider.dart';

class _FakeTaxonomyRepository implements TaxonomyRepository {
  _FakeTaxonomyRepository(this.nodes);

  final Map<String, TaxonomyNode> nodes;
  @override
  Future<void> save(TaxonomyNode node) async => nodes[node.uuid] = node;
  @override
  Future<TaxonomyNode?> getByUuid(String uuid) async => nodes[uuid];
  @override
  Future<List<TaxonomyNode>> getChildren(String parentUuid) async =>
      nodes.values.where((node) => node.parentUuid == parentUuid).toList();
  @override
  Future<List<TaxonomyNode>> getAll() async => nodes.values.toList();
}

class _FakeLibraryService extends LibraryService {
  _FakeLibraryService(this.result)
      : super(
          taxonomyRepository: _UnusedTaxonomyRepository(),
          noteRepository: _FakeNoteRepository(),
          citationRepository: _FakeCitationRepository(),
          bookmarkRepository: _FakeBookmarkRepository(),
          historyRepository: _FakeHistoryRepository(),
          generateUuid: () => 'unused',
          createSyncMetadata: () => _sync(),
          now: () => DateTime.utc(2026, 1, 1),
        );

  final TopicNotes result;
  int calls = 0;

  @override
  Future<TopicNotes> getTopicNotes(String topicUuid) async {
    calls++;
    return result;
  }
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

class _UnusedTaxonomyRepository implements TaxonomyRepository {
  @override
  Future<void> save(TaxonomyNode node) async => throw UnimplementedError();
  @override
  Future<TaxonomyNode?> getByUuid(String uuid) async =>
      throw UnimplementedError();
  @override
  Future<List<TaxonomyNode>> getChildren(String parentUuid) async =>
      throw UnimplementedError();
  @override
  Future<List<TaxonomyNode>> getAll() async => throw UnimplementedError();
}

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'test-device',
      syncRevision: 1,
    );

TaxonomyNode _node({
  required String uuid,
  String? parentUuid,
  required int depth,
  required int sortOrder,
}) =>
    TaxonomyNode(
      uuid: uuid,
      parentUuid: parentUuid,
      path: parentUuid == null ? uuid : '$parentUuid/$uuid',
      depth: depth,
      nodeType: NodeType.topic,
      title: uuid,
      slug: uuid,
      sortOrder: sortOrder,
      noteCount: 0,
      isUserCreated: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );

void main() {
  test('sorts children by sortOrder and does not load parent notes', () async {
    final root = _node(uuid: 'root', depth: 0, sortOrder: 0);
    final later = _node(
      uuid: 'later',
      parentUuid: 'root',
      depth: 1,
      sortOrder: 2,
    );
    final earlier = _node(
      uuid: 'earlier',
      parentUuid: 'root',
      depth: 1,
      sortOrder: 1,
    );
    final repository = _FakeTaxonomyRepository({
      root.uuid: root,
      later.uuid: later,
      earlier.uuid: earlier,
    });
    final libraryService = _FakeLibraryService(
      const TopicNotes(topicUuid: 'root', notes: []),
    );

    final container = ProviderContainer(
      overrides: [
        taxonomyRepositoryProvider.overrideWith((ref) async => repository),
        taxonomyNavigationServiceProvider.overrideWith(
          (ref) async =>
              TaxonomyNavigationService(taxonomyRepository: repository),
        ),
        libraryServiceProvider.overrideWith((ref) async => libraryService),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(taxonomyBrowserProvider('root').future);

    expect(result.children.map((node) => node.uuid), ['earlier', 'later']);
    expect(result.topicNotes, isNull);
    expect(libraryService.calls, 0);
  });

  test('loads notes for a leaf node', () async {
    final leaf = _node(uuid: 'leaf', depth: 0, sortOrder: 0);
    final repository = _FakeTaxonomyRepository({'leaf': leaf});
    final libraryService = _FakeLibraryService(
      const TopicNotes(topicUuid: 'leaf', notes: []),
    );

    final container = ProviderContainer(
      overrides: [
        taxonomyRepositoryProvider.overrideWith((ref) async => repository),
        taxonomyNavigationServiceProvider.overrideWith(
          (ref) async =>
              TaxonomyNavigationService(taxonomyRepository: repository),
        ),
        libraryServiceProvider.overrideWith((ref) async => libraryService),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(taxonomyBrowserProvider('leaf').future);

    expect(result.children, isEmpty);
    expect(result.topicNotes?.topicUuid, 'leaf');
    expect(libraryService.calls, 1);
  });

  test('throws when the requested taxonomy node is missing', () async {
    final repository = _FakeTaxonomyRepository({});
    final container = ProviderContainer(
      overrides: [
        taxonomyRepositoryProvider.overrideWith((ref) async => repository),
        taxonomyNavigationServiceProvider.overrideWith(
          (ref) async =>
              TaxonomyNavigationService(taxonomyRepository: repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(taxonomyBrowserProvider('missing').future),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'No taxonomy node found for uuid "missing".',
        ),
      ),
    );
  });
}
