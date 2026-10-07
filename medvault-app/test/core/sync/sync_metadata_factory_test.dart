import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/storage/device_identity.dart';
import 'package:medvault_app/core/sync/sync_metadata_factory.dart';
import 'package:medvault_app/core/time/clock.dart';

class FakeClock implements Clock {
  FakeClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  test('creates initial metadata for a new local record', () {
    final createdAt = DateTime.utc(2026, 10, 5, 12, 30);
    final deviceIdentity = DeviceIdentity(deviceId: 'device-123');
    final clock = FakeClock(createdAt);

    final factory = SyncMetadataFactory(
      deviceIdentity: deviceIdentity,
      clock: clock,
    );

    final metadata = factory();

    expect(metadata.remoteId, isNull);
    expect(metadata.lastModifiedLocal, createdAt);
    expect(metadata.lastSyncedAt, isNull);
    expect(metadata.isDirty, isTrue);
    expect(metadata.isDeleted, isFalse);
    expect(metadata.deviceId, 'device-123');
    expect(metadata.syncRevision, 1);
  });
}
