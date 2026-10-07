import 'package:isar/isar.dart';

part 'device_identity_model.g.dart';

/// Persists the unique identity of this MedVault installation.
@collection
class DeviceIdentityModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String deviceId;
}
