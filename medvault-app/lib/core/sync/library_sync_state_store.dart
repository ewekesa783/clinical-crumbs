import 'package:shared_preferences/shared_preferences.dart';

import 'library_sync_state.dart';

/// Persists shared-library sync state independently of user preferences.
class LibrarySyncStateStore {
  LibrarySyncStateStore({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  final SharedPreferences _preferences;

  static const _installedReleaseIdKey = 'library_sync.installed_release_id';
  static const _latestAvailableReleaseIdKey =
      'library_sync.latest_available_release_id';
  static const _lastSuccessfulCheckAtKey =
      'library_sync.last_successful_check_at';
  static const _lastSuccessfulUpdateAtKey =
      'library_sync.last_successful_update_at';

  LibrarySyncState load() {
    return LibrarySyncState(
      installedReleaseId: _readString(_installedReleaseIdKey),
      latestAvailableReleaseId: _readString(_latestAvailableReleaseIdKey),
      lastSuccessfulCheckAt: _readDateTime(_lastSuccessfulCheckAtKey),
      lastSuccessfulUpdateAt: _readDateTime(_lastSuccessfulUpdateAtKey),
    );
  }

  /// Saves the complete state. Null fields remove their stored values.
  Future<void> save(LibrarySyncState state) async {
    await _writeString(_installedReleaseIdKey, state.installedReleaseId);
    await _writeString(
      _latestAvailableReleaseIdKey,
      state.latestAvailableReleaseId,
    );
    await _writeDateTime(
      _lastSuccessfulCheckAtKey,
      state.lastSuccessfulCheckAt,
    );
    await _writeDateTime(
      _lastSuccessfulUpdateAtKey,
      state.lastSuccessfulUpdateAt,
    );
  }

  String? _readString(String key) {
    final value = _preferences.getString(key);
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  DateTime? _readDateTime(String key) {
    final value = _preferences.getString(key);
    if (value == null) return null;

    try {
      return DateTime.parse(value).toUtc();
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeString(String key, String? value) async {
    final success = value == null
        ? await _preferences.remove(key)
        : await _preferences.setString(key, value);

    if (!success) {
      throw StateError('Could not persist library sync state: $key');
    }
  }

  Future<void> _writeDateTime(String key, DateTime? value) async {
    await _writeString(key, value?.toUtc().toIso8601String());
  }
}
