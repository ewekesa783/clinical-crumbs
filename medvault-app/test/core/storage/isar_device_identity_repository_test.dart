import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/core/storage/device_identity_model.dart';
import 'package:medvault_app/core/storage/isar_device_identity_repository.dart';

void main() {
  late Isar isar;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('medvault_identity_test_');
    isar = await Isar.open(
      [DeviceIdentityModelSchema],
      directory: tempDir.path,
    );
  });

  tearDown(() async {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('creates and persists an identity when none exists', () async {
    var generatedCount = 0;

    final repository = IsarDeviceIdentityRepository(
      isar,
      generateUuid: () {
        generatedCount++;
        return 'generated-device-id';
      },
    );

    final first = await repository.getOrCreate();
    final second = await repository.getOrCreate();

    expect(first.deviceId, 'generated-device-id');
    expect(second.deviceId, first.deviceId);
    expect(generatedCount, 1);
  });

  test('returns the existing persisted identity without generating a new one',
      () async {
    final repository = IsarDeviceIdentityRepository(
      isar,
      generateUuid: () => 'should-not-be-used',
    );

    await isar.writeTxn(() async {
      await isar.deviceIdentityModels.put(
        DeviceIdentityModel()..deviceId = 'existing-device-id',
      );
    });

    final identity = await repository.getOrCreate();

    expect(identity.deviceId, 'existing-device-id');
  });
}
