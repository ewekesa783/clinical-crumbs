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

  setUp(async () {
    tempDir = await Directory.systemTemp.createTemp('medvault_isar_test_');
    isar = await Isar.open([HistoryModelSchema], directory: tempDir.path);
    repository = IsarHistoryRepository(isar);
  });

  tearDown(async () {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('getByNoteUuid returns the single entry for a note', async () {
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
      'same note', async () {
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
}
