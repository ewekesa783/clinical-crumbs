import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/bookmark_mapper.dart';
import 'package:medvault_app/features/library/domain/entities/bookmark.dart';

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'device-1',
      syncRevision: 1,
    );

void main() {
  test('BookmarkMapper round-trips all fields', () {
    final domain = Bookmark(
      uuid: 'bookmark-1',
      noteUuid: 'note-1',
      label: 'Review before exam',
      createdAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );

    final model = BookmarkMapper.toModel(domain);
    final roundTripped = BookmarkMapper.toDomain(model);

    expect(roundTripped.uuid, domain.uuid);
    expect(roundTripped.noteUuid, domain.noteUuid);
    expect(roundTripped.label, domain.label);
  });
}
