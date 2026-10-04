import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/note_model.dart';
import 'package:medvault_app/features/library/data/repositories/isar_note_repository.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'device-1',
      syncRevision: 1,
    );

void main() {
  late Isar isar;
  late Directory tempDir;
  late IsarNoteRepository repository;

  setUp(async () {
    tempDir = await Directory.systemTemp.createTemp('medvault_isar_test_');
    isar = await Isar.open([NoteModelSchema], directory: tempDir.path);
    repository = IsarNoteRepository(isar);
  });

  tearDown(async () {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('save then getByUuid returns the inserted note', async () {
    final note = Note(
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
    );

    await repository.save(note);
    final fetched = await repository.getByUuid('note-1');

    expect(fetched, isNotNull);
    expect(fetched!.title, 'Heart failure');
  });

  test('getByTopicAndMode resolves the composite unique index', async () {
    final note = Note(
      uuid: 'note-1',
      topicUuid: 'topic-1',
      mode: Mode.quickReview,
      title: 'Heart failure (quick review)',
      bodyMarkdown: 'body',
      tags: const [],
      citationOrder: const [],
      isPinned: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );

    await repository.save(note);
    final fetched =
        await repository.getByTopicAndMode('topic-1', Mode.quickReview);

    expect(fetched, isNotNull);
    expect(fetched!.uuid, 'note-1');

    final wrongMode =
        await repository.getByTopicAndMode('topic-1', Mode.detailedNotes);
    expect(wrongMode, isNull);
  });
}
