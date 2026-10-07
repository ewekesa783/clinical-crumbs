import 'package:isar/isar.dart';

import 'device_identity.dart';
import 'device_identity_mapper.dart';
import 'device_identity_model.dart';
import 'device_identity_repository.dart';

/// Isar-backed implementation of the persistent installation identity.
class IsarDeviceIdentityRepository implements DeviceIdentityRepository {
  IsarDeviceIdentityRepository(
    this._isar, {
    required String Function() generateUuid,
  }) : _generateUuid = generateUuid;

  final Isar _isar;
  final String Function() _generateUuid;

  @override
  Future<DeviceIdentity> getOrCreate() async {
    final existing = await _isar.deviceIdentityModels.where().findFirst();
    if (existing != null) {
      return DeviceIdentityMapper.toDomain(existing);
    }

    final identity = DeviceIdentity(deviceId: _generateUuid());
    final model = DeviceIdentityMapper.toModel(identity);

    await _isar.writeTxn(() async {
      await _isar.deviceIdentityModels.put(model);
    });

    return identity;
  }
}
