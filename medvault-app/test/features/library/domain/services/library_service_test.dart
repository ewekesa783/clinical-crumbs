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
  @override
  Future<List<TaxonomyNode>> getAll() async => _store.values.toList();
}

class _FakeNoteRepository implements NoteRepository {
  final Map<String, Note> _store = {};

  @override
  Future<void> save(Note note) async => _store[note.uuid] = note;

  @override
  Future<Note?> getByUuid(String uuid) async => _store[uuid];

  @override
  Future<List<Note>> getAll() async => _store.values.toList();

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
  Future<void> deleteByNoteUuid(String noteUuid) async {
    _store.removeWhere((_, bookmark) => bookmark.noteUuid == noteUuid);
  }

  @override
  Future<List<Bookmark>> getByNoteUuid(String noteUuid) async =>
      _store.values.where((b) => b.noteUuid == noteUuid).toList();

  @override
  Future<List<Bookmark>> getRecent({int limit = 10}) async {
    if (limit <= 0) return [];
    final entries = _store.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries.take(limit).toList();
  }
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

  @override
  Future<List<History>> getRecent({int? limit = 10}) async {
    if (limit != null && limit <= 0) return [];
    final entries = _store.values.toList()
      ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
    return (limit == null ? entries : entries.take(limit)).toList();
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

  Future<void> saveTopic(String uuid, {NodeType type = NodeType.topic}) async {
    final now = DateTime.utc(2026, 1, 1);
    await taxonomyRepository.save(TaxonomyNode(
      uuid: uuid,
      path: uuid,
      depth: type == NodeType.topic ? 2 : 1,
      nodeType: type,
      title: uuid,
      slug: uuid,
      sortOrder: 0,
      noteCount: 0,
      isUserCreated: true,
      createdAt: now,
      updatedAt: now,
      sync: _sync(),
    ));
  }

  Note makeEditableNote({
    String uuid = 'note-1',
    String topicUuid = 'topic-1',
    Mode mode = Mode.detailedNotes,
    SyncMetadata? sync,
  }) {
    final createdAt = DateTime.utc(2025, 1, 1);
    return Note(
      uuid: uuid,
      topicUuid: topicUuid,
      mode: mode,
      title: 'Original title',
      bodyMarkdown: 'User-authored body must remain untouched.',
      plainTextExtract: 'Original extract',
      tags: const ['old-tag'],
      citationOrder: const ['citation-1'],
      isPinned: true,
      createdAt: createdAt,
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: sync ?? SyncMetadata(
        remoteId: 'remote-1',
        lastModifiedLocal: DateTime.utc(2026, 1, 1),
        lastSyncedAt: DateTime.utc(2026, 1, 2),
        isDirty: false,
        isDeleted: false,
        deviceId: 'device-original',
        syncRevision: 7,
      ),
    );
  }

  test('updateNoteMetadata preserves content and sync identity', () async {
    await saveTopic('topic-1');
    await saveTopic('topic-2');
    final original = makeEditableNote();
    await noteRepository.save(original);

    final updated = await service.updateNoteMetadata(
      noteUuid: original.uuid,
      title: '  Updated title  ',
      tags: [' alpha ', 'ALPHA', '', 'beta'],
      topicUuid: 'topic-2',
    );

    expect(updated.uuid, original.uuid);
    expect(updated.topicUuid, 'topic-2');
    expect(updated.title, 'Updated title');
    expect(updated.tags, ['alpha', 'beta']);
    expect(updated.mode, original.mode);
    expect(updated.bodyMarkdown, original.bodyMarkdown);
    expect(updated.plainTextExtract, original.plainTextExtract);
    expect(updated.citationOrder, original.citationOrder);
    expect(updated.isPinned, original.isPinned);
    expect(updated.createdAt, original.createdAt);
    expect(updated.updatedAt, DateTime.utc(2026, 6, 1));
    expect(updated.sync.remoteId, 'remote-1');
    expect(updated.sync.lastSyncedAt, DateTime.utc(2026, 1, 2));
    expect(updated.sync.deviceId, 'device-original');
    expect(updated.sync.isDirty, isTrue);
    expect(updated.sync.isDeleted, isFalse);
    expect(updated.sync.syncRevision, 8);

    final stored = await noteRepository.getByUuid(original.uuid);
    expect(stored, isNotNull);
    expect(stored!.title, 'Updated title');
    expect(stored.bodyMarkdown, original.bodyMarkdown);
  });

  test('updateNoteMetadata rejects an empty title without saving', () async {
    await saveTopic('topic-1');
    final original = makeEditableNote();
    await noteRepository.save(original);

    await expectLater(
      service.updateNoteMetadata(
        noteUuid: original.uuid,
        title: '  ',
        tags: const [],
        topicUuid: 'topic-1',
      ),
      throwsArgumentError,
    );
    expect((await noteRepository.getByUuid(original.uuid))!.title,
        original.title);
  });

  test('updateNoteMetadata rejects a missing destination topic', () async {
    await saveTopic('topic-1');
    final original = makeEditableNote();
    await noteRepository.save(original);

    await expectLater(
      service.updateNoteMetadata(
        noteUuid: original.uuid,
        title: 'Updated',
        tags: const [],
        topicUuid: 'missing-topic',
      ),
      throwsA(isA<StateError>()),
    );
    expect((await noteRepository.getByUuid(original.uuid))!.topicUuid,
        original.topicUuid);
  });

  test('updateNoteMetadata rejects moving into an occupied mode', () async {
    await saveTopic('topic-1');
    await saveTopic('topic-2');
    await noteRepository.save(makeEditableNote());
    await noteRepository.save(makeEditableNote(
      uuid: 'note-2',
      topicUuid: 'topic-2',
    ));

    await expectLater(
      service.updateNoteMetadata(
        noteUuid: 'note-1',
        title: 'Updated',
        tags: const [],
        topicUuid: 'topic-2',
      ),
      throwsA(isA<StateError>()),
    );
    expect((await noteRepository.getByUuid('note-1'))!.topicUuid, 'topic-1');
  });

  test('updateNoteMetadata rejects a non-topic destination', () async {
    await saveTopic('topic-1');
    await saveTopic('subject-1', type: NodeType.subject);
    final original = makeEditableNote();
    await noteRepository.save(original);

    await expectLater(
      service.updateNoteMetadata(
        noteUuid: original.uuid,
        title: 'Updated',
        tags: const [],
        topicUuid: 'subject-1',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('updateNoteMetadata rejects deleted notes', () async {
    await saveTopic('topic-1');
    final original = makeEditableNote(
      sync: SyncMetadata(
        lastModifiedLocal: DateTime.utc(2026, 1, 1),
        isDirty: true,
        isDeleted: true,
        deviceId: 'device-1',
        syncRevision: 2,
      ),
    );
    await noteRepository.save(original);

    await expectLater(
      service.updateNoteMetadata(
        noteUuid: original.uuid,
        title: 'Updated',
        tags: const [],
        topicUuid: 'topic-1',
      ),
      throwsA(isA<StateError>()),
    );
    expect((await noteRepository.getByUuid(original.uuid))!.title,
        original.title);
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

  test('getRecentlyViewedNotes returns notes in recency order', () async {
    final now = DateTime.utc(2026, 1, 1);
    for (final item in [
      ('note-old', 'Older note', DateTime.utc(2026, 1, 1)),
      ('note-new', 'Newer note', DateTime.utc(2026, 1, 3)),
      ('note-middle', 'Middle note', DateTime.utc(2026, 1, 2)),
    ]) {
      await noteRepository.save(Note(
        uuid: item.$1,
        topicUuid: 'topic-1',
        mode: Mode.detailedNotes,
        title: item.$2,
        bodyMarkdown: 'Synthetic test fixture',
        tags: const [],
        citationOrder: const [],
        isPinned: false,
        createdAt: now,
        updatedAt: now,
        sync: _sync(),
      ));
      await historyRepository.save(History(
        uuid: 'history-${item.$1}',
        noteUuid: item.$1,
        viewedAt: item.$3,
        sync: _sync(),
      ));
    }

    final notes = await service.getRecentlyViewedNotes();

    expect(notes.map((note) => note.uuid).toList(),
        ['note-new', 'note-middle', 'note-old']);
    expect(await service.getRecentlyViewedNotes(limit: 2), hasLength(2));
    expect(await service.getRecentlyViewedNotes(limit: 0), isEmpty);
  });

  test('getRecentlyViewedNotes skips history for missing notes', () async {
    await historyRepository.save(History(
      uuid: 'history-missing',
      noteUuid: 'deleted-note',
      viewedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    ));

    expect(await service.getRecentlyViewedNotes(), isEmpty);
  });

  test('getBookmarkedNotes returns unique existing notes newest first',
      () async {
    final now = DateTime.utc(2026, 1, 1);
    for (final item in [
      ('note-a', 'Note A'),
      ('note-b', 'Note B'),
    ]) {
      await noteRepository.save(Note(
        uuid: item.$1,
        topicUuid: 'topic-1',
        mode: Mode.detailedNotes,
        title: item.$2,
        bodyMarkdown: 'Synthetic test fixture',
        tags: const [],
        citationOrder: const [],
        isPinned: false,
        createdAt: now,
        updatedAt: now,
        sync: _sync(),
      ));
    }

    await bookmarkRepository.save(Bookmark(
      uuid: 'bookmark-a-old',
      noteUuid: 'note-a',
      label: 'Older',
      createdAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    ));
    await bookmarkRepository.save(Bookmark(
      uuid: 'bookmark-b',
      noteUuid: 'note-b',
      label: null,
      createdAt: DateTime.utc(2026, 1, 3),
      sync: _sync(),
    ));
    await bookmarkRepository.save(Bookmark(
      uuid: 'bookmark-a-new',
      noteUuid: 'note-a',
      label: 'Newer',
      createdAt: DateTime.utc(2026, 1, 2),
      sync: _sync(),
    ));
    await bookmarkRepository.save(Bookmark(
      uuid: 'bookmark-missing',
      noteUuid: 'deleted-note',
      label: null,
      createdAt: DateTime.utc(2026, 1, 4),
      sync: _sync(),
    ));

    final notes = await service.getBookmarkedNotes();

    expect(notes.map((note) => note.uuid).toList(), ['note-b', 'note-a']);
    expect(await service.getBookmarkedNotes(limit: 0), isEmpty);
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
