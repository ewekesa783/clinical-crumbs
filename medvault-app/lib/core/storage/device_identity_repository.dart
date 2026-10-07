import 'device_identity.dart';

/// Provides access to the persistent identity of this MedVault installation.
abstract interface class DeviceIdentityRepository {
  Future<DeviceIdentity> getOrCreate();
}
