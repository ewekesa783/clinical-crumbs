import '../storage/device_identity.dart';
import '../time/clock.dart';
import 'sync_metadata.dart';

/// Creates initial synchronization metadata for a newly created local record.
class SyncMetadataFactory {
  const SyncMetadataFactory({
    required DeviceIdentity deviceIdentity,
    required Clock clock,
  })  : _deviceIdentity = deviceIdentity,
        _clock = clock;

  final DeviceIdentity _deviceIdentity;
  final Clock _clock;

  SyncMetadata call() {
    return SyncMetadata(
      remoteId: null,
      lastModifiedLocal: _clock.now(),
      lastSyncedAt: null,
      isDirty: true,
      isDeleted: false,
      deviceId: _deviceIdentity.deviceId,
      syncRevision: 1,
    );
  }
}
