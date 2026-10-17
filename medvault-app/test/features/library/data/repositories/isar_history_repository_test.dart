import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/history_model.dart';
import 'package:medvault_app/features/library/data/repositories/isar_history_repository.dart';
import 'package:medvault_app/features/library/domain/entities/history.dart';

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
  late IsarHistoryRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('medvault_isar_test_');
    isar = await Isar.open([HistoryModelSchema], directory: tempDir.path);
    repository = IsarHistoryRepository(isar);
  });

  tearDown(() async {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('getByNoteUuid returns the single entry for a note', () async {
    await repository.save(History(
      uuid: 'history-1',
      noteUuid: 'note-1',
      viewedAt: DateTime.utc(2026, 1, 1, 12),
      sync: _sync(),
    ));

    final fetched = await repository.getByNoteUuid('note-1');
    expect(fetched, isNotNull);
    expect(fetched!.uuid, 'history-1');
  });

  test('unique noteUuid index rejects a second distinct entry for the '
      'same note', () async {
    await repository.save(History(
      uuid: 'history-1',
      noteUuid: 'note-1',
      viewedAt: DateTime.utc(2026, 1, 1, 12),
      sync: _sync(),
    ));

    // save() does not perform upsert-by-noteUuid (see HistoryRepository
    // doc comment); inserting a second distinct uuid for the same
    // noteUuid violates the unique index at the Isar storage layer.
    expect(
      () => repository.save(History(
        uuid: 'history-2',
        noteUuid: 'note-1',
        viewedAt: DateTime.utc(2026, 1, 2, 9),
        sync: _sync(),
      )),
      throwsA(anything),
    );
  });


  test('getRecent returns entries newest first', () async {
    await repository.save(History(
      uuid: 'history-old',
      noteUuid: 'note-old',
      viewedAt: DateTime.utc(2026, 1, 1, 12),
      sync: _sync(),
    ));
    await repository.save(History(
      uuid: 'history-new',
      noteUuid: 'note-new',
      viewedAt: DateTime.utc(2026, 1, 3, 12),
      sync: _sync(),
    ));
    await repository.save(History(
      uuid: 'history-middle',
      noteUuid: 'note-middle',
      viewedAt: DateTime.utc(2026, 1, 2, 12),
      sync: _sync(),
    ));

    final recent = await repository.getRecent();

    expect(
      recent.map((entry) => entry.noteUuid).toList(),
      ['note-new', 'note-middle', 'note-old'],
    );
  });

  test('getRecent respects the requested limit', () async {
    for (var day = 1; day <= 3; day++) {
      await repository.save(History(
        uuid: 'history-$day',
        noteUuid: 'note-$day',
        viewedAt: DateTime.utc(2026, 1, day),
        sync: _sync(),
      ));
    }

    final recent = await repository.getRecent(limit: 2);

    expect(recent, hasLength(2));
    expect(recent.map((entry) => entry.noteUuid).toList(),
        ['note-3', 'note-2']);
  });

  test('getRecent returns an empty list for a non-positive limit',
      () async {
    await repository.save(History(
      uuid: 'history-1',
      noteUuid: 'note-1',
      viewedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    ));

    expect(await repository.getRecent(limit: 0), isEmpty);
    expect(await repository.getRecent(limit: -1), isEmpty);
  });

}
