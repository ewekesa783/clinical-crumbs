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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('medvault_isar_test_');
    isar = await Isar.open([NoteModelSchema], directory: tempDir.path);
    repository = IsarNoteRepository(isar);
  });

  tearDown(() async {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('save then getByUuid returns the inserted note', () async {
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

  test('getByTopicAndMode resolves the composite unique index', () async {
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

  Note makeNote({
    required String uuid,
    required String topicUuid,
    required String title,
    String bodyMarkdown = 'Ordinary body text',
    String? plainTextExtract,
    List<String> tags = const [],
    Mode mode = Mode.detailedNotes,
  }) {
    return Note(
      uuid: uuid,
      topicUuid: topicUuid,
      mode: mode,
      title: title,
      bodyMarkdown: bodyMarkdown,
      plainTextExtract: plainTextExtract,
      tags: tags,
      citationOrder: const [],
      isPinned: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );
  }

  test('search matches titles, extracts, Markdown, and tags', () async {
    await repository.save(makeNote(
      uuid: 'title-note',
      topicUuid: 'topic-title',
      title: 'Heart Failure',
    ));
    await repository.save(makeNote(
      uuid: 'extract-note',
      topicUuid: 'topic-extract',
      title: 'Respiratory Notes',
      plainTextExtract: 'Management of ACUTE ASTHMA',
    ));
    await repository.save(makeNote(
      uuid: 'body-note',
      topicUuid: 'topic-body',
      title: 'General Notes',
      bodyMarkdown: 'Recognising diabetic ketoacidosis',
    ));
    await repository.save(makeNote(
      uuid: 'tag-note',
      topicUuid: 'topic-tag',
      title: 'Revision Notes',
      tags: const ['Paediatrics', 'Nephrology'],
    ));

    expect(
      (await repository.search('heart')).map((note) => note.uuid),
      contains('title-note'),
    );
    expect(
      (await repository.search('acute asthma')).map((note) => note.uuid),
      contains('extract-note'),
    );
    expect(
      (await repository.search('ketoacidosis')).map((note) => note.uuid),
      contains('body-note'),
    );
    expect(
      (await repository.search('NEPHROLOGY')).map((note) => note.uuid),
      contains('tag-note'),
    );
  });

  test('saving an existing UUID updates the note without duplicating it',
      () async {
    final original = makeNote(
      uuid: 'update-note',
      topicUuid: 'topic-update',
      title: 'Original title',
      bodyMarkdown: 'Original body',
    );
    await repository.save(original);

    final updated = makeNote(
      uuid: 'update-note',
      topicUuid: 'topic-update',
      title: 'Updated title',
      bodyMarkdown: 'Updated body',
    );
    await repository.save(updated);

    final fetched = await repository.getByUuid('update-note');
    final results = await repository.search('Updated title');

    expect(fetched, isNotNull);
    expect(fetched!.title, 'Updated title');
    expect(fetched.bodyMarkdown, 'Updated body');
    expect(results.where((note) => note.uuid == 'update-note').length, 1);
  });

  test('search returns no results for a blank query', () async {
    await repository.save(makeNote(
      uuid: 'note-1',
      topicUuid: 'topic-1',
      title: 'Heart Failure',
    ));

    expect(await repository.search('   '), isEmpty);
  });
}
