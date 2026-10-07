import 'device_identity.dart';
import 'device_identity_model.dart';

/// Converts between the domain device identity and its Isar model.
class DeviceIdentityMapper {
  const DeviceIdentityMapper._();

  static DeviceIdentity toDomain(DeviceIdentityModel model) {
    return DeviceIdentity(deviceId: model.deviceId);
  }

  static DeviceIdentityModel toModel(DeviceIdentity domain) {
    return DeviceIdentityModel()..deviceId = domain.deviceId;
  }
}
