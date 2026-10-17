import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/domain/entities/history.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
import 'package:medvault_app/features/library/domain/repositories/history_repository.dart';
import 'package:medvault_app/features/library/domain/repositories/note_repository.dart';
import 'package:medvault_app/features/library/domain/services/recently_viewed_service.dart';

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

class _FakeNoteRepository implements NoteRepository {
  final Map<String, Note> _store = {};

  @override
  Future<void> save(Note note) async => _store[note.uuid] = note;

  @override
  Future<Note?> getByUuid(String uuid) async => _store[uuid];

  @override
  @override
  Future<List<Note>> getAll() async => [];

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

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'device-1',
      syncRevision: 1,
    );

void main() {
  test(
      'getRecentlyViewedEntry resolves the Note, not just the History '
      'entry (final A.3A DTO shape: Note + viewedAt only)', () async {
    final historyRepository = _FakeHistoryRepository();
    final noteRepository = _FakeNoteRepository();

    await noteRepository.save(Note(
      uuid: 'note-1',
      topicUuid: 'topic-1',
      mode: Mode.detailedNotes,
      title: 'Heart failure',
      bodyMarkdown: 'body',
      tags: const [],
      citationOrder: const [],
      isPinned: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    ));
    await historyRepository.save(History(
      uuid: 'history-1',
      noteUuid: 'note-1',
      viewedAt: DateTime.utc(2026, 1, 5),
      sync: _sync(),
    ));

    final service = RecentlyViewedService(
      historyRepository: historyRepository,
      noteRepository: noteRepository,
    );

    final entry = await service.getRecentlyViewedEntry('note-1');

    expect(entry, isNotNull);
    expect(entry!.note.uuid, 'note-1');
    expect(entry.viewedAt, DateTime.utc(2026, 1, 5));
  });

  test('returns null when no history entry exists for the note', () async {
    final service = RecentlyViewedService(
      historyRepository: _FakeHistoryRepository(),
      noteRepository: _FakeNoteRepository(),
    );

    expect(await service.getRecentlyViewedEntry('note-404'), isNull);
  });

  test('returns null when history exists but its note is missing', () async {
    final historyRepository = _FakeHistoryRepository();
    await historyRepository.save(History(
      uuid: 'history-1',
      noteUuid: 'note-404',
      viewedAt: DateTime.utc(2026, 1, 5),
      sync: _sync(),
    ));

    final service = RecentlyViewedService(
      historyRepository: historyRepository,
      noteRepository: _FakeNoteRepository(),
    );

    expect(await service.getRecentlyViewedEntry('note-404'), isNull);
  });
}
