import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/di/injector.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
import 'package:medvault_app/features/library/domain/repositories/note_repository.dart';
import 'package:medvault_app/features/library/presentation/providers/note_search_provider.dart';

class _FakeNoteRepository implements NoteRepository {
  String? receivedQuery;
  List<Note> results = [];
  Object? searchError;

  @override
  Future<List<Note>> search(String query) async {
    receivedQuery = query;
    if (searchError != null) throw searchError!;
    return results;
  }

  @override
  Future<void> save(Note note) async {}

  @override
  Future<Note?> getByUuid(String uuid) async => null;

  @override
  Future<Note?> getByTopicAndMode(String topicUuid, Mode mode) async => null;
}

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'test-device',
      syncRevision: 1,
    );

Note _note(String uuid) => Note(
      uuid: uuid,
      topicUuid: 'topic-1',
      mode: Mode.detailedNotes,
      title: 'Note $uuid',
      bodyMarkdown: 'Body',
      tags: const [],
      citationOrder: const [],
      isPinned: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );

void main() {
  test('passes the query through and returns repository results', () async {
    final repository = _FakeNoteRepository()
      ..results = [_note('note-1'), _note('note-2')];
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);

    final result =
        await container.read(noteSearchProvider('  heart failure  ').future);

    expect(repository.receivedQuery, '  heart failure  ');
    expect(result, same(repository.results));
    expect(result.map((note) => note.uuid), ['note-1', 'note-2']);
  });

  test('propagates repository search errors', () async {
    final error = StateError('Search failed');
    final repository = _FakeNoteRepository()..searchError = error;
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(noteSearchProvider('heart').future),
      throwsA(same(error)),
    );
    expect(repository.receivedQuery, 'heart');
  });
}
