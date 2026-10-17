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

  test('saving an existing bookmark uuid updates its record', () async {
    await repository.save(Bookmark(
      uuid: 'bookmark-1',
      noteUuid: 'note-1',
      label: 'Original',
      createdAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    ));

    await repository.save(Bookmark(
      uuid: 'bookmark-1',
      noteUuid: 'note-1',
      label: 'Updated',
      createdAt: DateTime.utc(2026, 1, 2),
      sync: _sync(),
    ));

    final fetched = await repository.getByUuid('bookmark-1');
    final bookmarks = await repository.getByNoteUuid('note-1');

    expect(fetched, isNotNull);
    expect(fetched!.label, 'Updated');
    expect(
      fetched.createdAt.millisecondsSinceEpoch,
      DateTime.utc(2026, 1, 2).millisecondsSinceEpoch,
    );
    expect(bookmarks, hasLength(1));
  });

  test('getRecent returns bookmarks newest first', () async {
    await repository.save(Bookmark(
      uuid: 'bookmark-old',
      noteUuid: 'note-old',
      label: 'Old',
      createdAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    ));
    await repository.save(Bookmark(
      uuid: 'bookmark-new',
      noteUuid: 'note-new',
      label: 'New',
      createdAt: DateTime.utc(2026, 1, 3),
      sync: _sync(),
    ));
    await repository.save(Bookmark(
      uuid: 'bookmark-middle',
      noteUuid: 'note-middle',
      label: 'Middle',
      createdAt: DateTime.utc(2026, 1, 2),
      sync: _sync(),
    ));

    final bookmarks = await repository.getRecent();

    expect(
      bookmarks.map((bookmark) => bookmark.uuid).toList(),
      ['bookmark-new', 'bookmark-middle', 'bookmark-old'],
    );
  });

  test('getRecent respects the requested limit', () async {
    for (var i = 1; i <= 3; i++) {
      await repository.save(Bookmark(
        uuid: 'bookmark-$i',
        noteUuid: 'note-$i',
        label: 'Bookmark $i',
        createdAt: DateTime.utc(2026, 1, i),
        sync: _sync(),
      ));
    }

    final bookmarks = await repository.getRecent(limit: 2);

    expect(bookmarks, hasLength(2));
    expect(
      bookmarks.map((bookmark) => bookmark.uuid).toList(),
      ['bookmark-3', 'bookmark-2'],
    );
  });

  test('getRecent returns an empty list for non-positive limits', () async {
    await repository.save(Bookmark(
      uuid: 'bookmark-1',
      noteUuid: 'note-1',
      label: 'Bookmark',
      createdAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    ));

    expect(await repository.getRecent(limit: 0), isEmpty);
    expect(await repository.getRecent(limit: -1), isEmpty);
  });

}
