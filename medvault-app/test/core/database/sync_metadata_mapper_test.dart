import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/database/sync_metadata_mapper.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';

void main() {
  group('SyncMetadataMapper', () {
    test('toModel then toDomain round-trips all fields', () {
      final domain = SyncMetadata(
        remoteId: 'remote-123',
        lastModifiedLocal: DateTime.utc(2026, 1, 1),
        lastSyncedAt: DateTime.utc(2026, 1, 2),
        isDirty: true,
        isDeleted: false,
        deviceId: 'device-abc',
        syncRevision: 7,
      );

      final model = SyncMetadataMapper.toModel(domain);
      final roundTripped = SyncMetadataMapper.toDomain(model);

      expect(roundTripped.remoteId, domain.remoteId);
      expect(roundTripped.lastModifiedLocal, domain.lastModifiedLocal);
      expect(roundTripped.lastSyncedAt, domain.lastSyncedAt);
      expect(roundTripped.isDirty, domain.isDirty);
      expect(roundTripped.isDeleted, domain.isDeleted);
      expect(roundTripped.deviceId, domain.deviceId);
      expect(roundTripped.syncRevision, domain.syncRevision);
    });

    test('handles null remoteId and lastSyncedAt', () {
      final domain = SyncMetadata(
        remoteId: null,
        lastModifiedLocal: DateTime.utc(2026, 1, 1),
        lastSyncedAt: null,
        isDirty: false,
        isDeleted: false,
        deviceId: 'device-abc',
        syncRevision: 0,
      );

      final model = SyncMetadataMapper.toModel(domain);
      expect(model.remoteId, isNull);
      expect(model.lastSyncedAt, isNull);

      final roundTripped = SyncMetadataMapper.toDomain(model);
      expect(roundTripped.remoteId, isNull);
      expect(roundTripped.lastSyncedAt, isNull);
    });
  });
}
