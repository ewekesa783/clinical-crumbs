import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/bookmark_model.dart';
import 'package:medvault_app/features/library/data/repositories/isar_bookmark_repository.dart';
import 'package:medvault_app/features/library/domain/entities/bookmark.dart';

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
  late IsarBookmarkRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('medvault_isar_test_');
    isar = await Isar.open([BookmarkModelSchema], directory: tempDir.path);
    repository = IsarBookmarkRepository(isar);
  });

  tearDown(() async {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('a note may have more than one bookmark (non-unique index)', () async {
    await repository.save(Bookmark(
      uuid: 'bookmark-1',
      noteUuid: 'note-1',
      label: 'First',
      createdAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    ));
    await repository.save(Bookmark(
      uuid: 'bookmark-2',
      noteUuid: 'note-1',
      label: 'Second',
      createdAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    ));

    final bookmarks = await repository.getByNoteUuid('note-1');
    expect(bookmarks, hasLength(2));
  });
}
