import 'package:flutter_test/flutter_test.dart';
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

// In-memory fake repositories, per this project's established testing
// convention for service-layer tests (no real Isar instance is needed
// to test coordination logic).

class _FakeTaxonomyRepository implements TaxonomyRepository {
  final Map<String, TaxonomyNode> _store = {};

  @override
  Future<void> save(TaxonomyNode node) async => _store[node.uuid] = node;

  @override
  Future<TaxonomyNode?> getByUuid(String uuid) async => _store[uuid];

  @override
  Future<List<TaxonomyNode>> getChildren(String parentUuid) async =>
      _store.values.where((n) => n.parentUuid == parentUuid).toList();
}

class _FakeNoteRepository implements NoteRepository {
  final Map<String, Note> _store = {};

  @override
  Future<void> save(Note note) async => _store[note.uuid] = note;

  @override
  Future<Note?> getByUuid(String uuid) async => _store[uuid];

  @override
  Future<List<Note>> search(String query) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return [];
    return _store.values.where((note) {
      return note.title.toLowerCase().contains(term) ||
          (note.plainTextExtract ?? note.bodyMarkdown)
              .toLowerCase()
              .contains(term) ||
          note.tags.any((tag) => tag.toLowerCase().contains(term));
    }).toList();
  }

  @override
  Future<Note?> getByTopicAndMode(String topicUuid, Mode mode) async {
    for (final note in _store.values) {
      if (note.topicUuid == topicUuid && note.mode == mode) return note;
    }
    return null;
  }
}

class _FakeCitationRepository implements CitationRepository {
  final Map<String, Citation> _store = {};

  @override
  Future<void> save(Citation citation) async =>
      _store[citation.uuid] = citation;

  @override
  Future<Citation?> getByUuid(String uuid) async => _store[uuid];

  @override
  Future<List<Citation>> getByUuids(List<String> uuids) async {
    final result = <Citation>[];
    for (final uuid in uuids) {
      final c = _store[uuid];
      if (c != null) result.add(c);
    }
    return result;
  }
}

class _FakeBookmarkRepository implements BookmarkRepository {
  final Map<String, Bookmark> _store = {};

  @override
  Future<void> save(Bookmark bookmark) async =>
      _store[bookmark.uuid] = bookmark;

  @override
  Future<Bookmark?> getByUuid(String uuid) async => _store[uuid];

  @override
  Future<List<Bookmark>> getByNoteUuid(String noteUuid) async =>
      _store.values.where((b) => b.noteUuid == noteUuid).toList();
}

class _FakeHistoryRepository implements HistoryRepository {
  final Map<String, History> _store = {};

  @override
  Future<void> save(History history) async => _store[history.uuid] = history;

  @override
  Future<History?> getByUuid(String uuid) async => _store[uuid];

  @override
  Future<History?> getByNoteUuid(String noteUuid) async {
    for (final h in _store.values) {
      if (h.noteUuid == noteUuid) return h;
    }
    return null;
  }
}

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'device-1',
      syncRevision: 1,
    );

void main() {
  late _FakeTaxonomyRepository taxonomyRepository;
  late _FakeNoteRepository noteRepository;
  late _FakeCitationRepository citationRepository;
  late _FakeBookmarkRepository bookmarkRepository;
  late _FakeHistoryRepository historyRepository;
  late LibraryService service;
  late int uuidCounter;

  setUp(() {
    taxonomyRepository = _FakeTaxonomyRepository();
    noteRepository = _FakeNoteRepository();
    citationRepository = _FakeCitationRepository();
    bookmarkRepository = _FakeBookmarkRepository();
    historyRepository = _FakeHistoryRepository();
    uuidCounter = 0;

    service = LibraryService(
      taxonomyRepository: taxonomyRepository,
      noteRepository: noteRepository,
      citationRepository: citationRepository,
      bookmarkRepository: bookmarkRepository,
      historyRepository: historyRepository,
      generateUuid: () => 'generated-${uuidCounter++}',
      createSyncMetadata: _sync,
      now: () => DateTime.utc(2026, 6, 1),
    );
  });

  test('recordNoteViewed creates a new History entry on first view', () async {
    await service.recordNoteViewed('note-1');

    final entry = await historyRepository.getByNoteUuid('note-1');
    expect(entry, isNotNull);
    expect(entry!.uuid, 'generated-0');
  });

  test(
      'recordNoteViewed reuses the existing uuid on a repeat view '
      '(via _uuidFor)', () async {
    await service.recordNoteViewed('note-1',
        viewedAt: DateTime.utc(2026, 1, 1));
    final first = await historyRepository.getByNoteUuid('note-1');

    await service.recordNoteViewed('note-1',
        viewedAt: DateTime.utc(2026, 1, 2));
    final second = await historyRepository.getByNoteUuid('note-1');

    expect(second!.uuid, first!.uuid);
    expect(second.viewedAt, DateTime.utc(2026, 1, 2));
  });

  test('getTopicNotes returns available notes across all modes', () async {
    final now = DateTime.utc(2026, 1, 1);
    await taxonomyRepository.save(TaxonomyNode(
      uuid: 'topic-1',
      path: 'subject-1/topic-1',
      depth: 1,
      nodeType: NodeType.topic,
      title: 'Topic',
      slug: 'topic',
      sortOrder: 0,
      noteCount: 3,
      isUserCreated: false,
      createdAt: now,
      updatedAt: now,
      sync: _sync(),
    ));

    final expectedNotes = <Note>[];
    for (final mode in [
      Mode.detailedNotes,
      Mode.quickReview,
    ]) {
      final note = Note(
        uuid: 'note-${mode.name}',
        topicUuid: 'topic-1',
        mode: mode,
        title: mode.name,
        bodyMarkdown: 'Body for ${mode.name}',
        tags: const [],
        citationOrder: const [],
        isPinned: false,
        createdAt: now,
        updatedAt: now,
        sync: _sync(),
      );
      expectedNotes.add(note);
      await noteRepository.save(note);
    }

    final result = await service.getTopicNotes('topic-1');

    expect(result.topicUuid, 'topic-1');
    expect(result.notes, hasLength(2));
    expect(result.notes.map((note) => note.uuid).toSet(),
        expectedNotes.map((note) => note.uuid).toSet());
    expect(
        result.notes.any((note) => note.mode == Mode.visualLearning), isFalse);
  });

  test('getTopicNotes throws StateError when the topic does not exist',
      () async {
    await expectLater(
      service.getTopicNotes('missing-topic'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'No taxonomy node found for uuid "missing-topic".',
        ),
      ),
    );
  });

  test('getNoteWithCitations returns null when the note is missing', () async {
    final result = await service.getNoteWithCitations('missing-note');

    expect(result, isNull);
  });

  test('getNoteWithCitations resolves citations in citationOrder', () async {
    await citationRepository.save(Citation(
      uuid: 'cite-1',
      sourceType: SourceType.textbook,
      title: 'First',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    ));
    await noteRepository.save(Note(
      uuid: 'note-1',
      topicUuid: 'topic-1',
      mode: Mode.detailedNotes,
      title: 'Note',
      bodyMarkdown: 'body',
      tags: const [],
      citationOrder: const ['cite-1'],
      isPinned: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    ));

    final result = await service.getNoteWithCitations('note-1');
    expect(result, isNotNull);
    expect(result!.citations, hasLength(1));
    expect(result.citations.first.uuid, 'cite-1');
  });

  test('bookmarkNote creates distinct bookmarks and preserves labels',
      () async {
    final first = await service.bookmarkNote('note-1', label: 'First label');
    final second = await service.bookmarkNote('note-1', label: 'Second label');

    final saved = await bookmarkRepository.getByNoteUuid('note-1');

    expect(first.uuid, isNot(second.uuid));
    expect(first.label, 'First label');
    expect(second.label, 'Second label');
    expect(saved, hasLength(2));
    expect(saved.map((bookmark) => bookmark.label).toSet(),
        {'First label', 'Second label'});
    expect(await service.isNoteBookmarked('note-1'), isTrue);
  });

  test('bookmarkNote then isNoteBookmarked reflects the new bookmark',
      () async {
    expect(await service.isNoteBookmarked('note-1'), isFalse);
    await service.bookmarkNote('note-1');
    expect(await service.isNoteBookmarked('note-1'), isTrue);
  });
}
