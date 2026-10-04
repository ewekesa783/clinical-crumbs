import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/history_mapper.dart';
import 'package:medvault_app/features/library/domain/entities/history.dart';

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'device-1',
      syncRevision: 1,
    );

void main() {
  test('HistoryMapper round-trips all fields', () {
    final domain = History(
      uuid: 'history-1',
      noteUuid: 'note-1',
      viewedAt: DateTime.utc(2026, 1, 1, 12),
      sync: _sync(),
    );

    final model = HistoryMapper.toModel(domain);
    final roundTripped = HistoryMapper.toDomain(model);

    expect(roundTripped.uuid, domain.uuid);
    expect(roundTripped.noteUuid, domain.noteUuid);
    expect(roundTripped.viewedAt, domain.viewedAt);
  });
}
