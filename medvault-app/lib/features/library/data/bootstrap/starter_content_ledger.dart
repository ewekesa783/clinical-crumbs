import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks bundled starter resources and intentional user deletions.
///
/// UUIDs are stable across app versions. User-imported resources must not be
/// recorded as starter-resource deletions.
class StarterContentLedger {
  StarterContentLedger(this._preferences);

  static const storageKey = 'clinical_crumbs_starter_content_ledger_v1';

  final SharedPreferences _preferences;

  Map<String, dynamic> _read() {
    final encoded = _preferences.getString(storageKey);
    if (encoded == null || encoded.isEmpty) {
      return <String, dynamic>{
        'knownResourceUuids': <String>[],
        'deletedResourceUuids': <String>[],
        'installedContentVersion': null,
      };
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) throw const FormatException();

      final known = decoded['knownResourceUuids'];
      final deleted = decoded['deletedResourceUuids'];
      if (known is! List ||
          deleted is! List ||
          known.any((value) => value is! String) ||
          deleted.any((value) => value is! String)) {
        throw const FormatException();
      }

      return <String, dynamic>{
        'knownResourceUuids': known.cast<String>(),
        'deletedResourceUuids': deleted.cast<String>(),
        'installedContentVersion': decoded['installedContentVersion'] is int
            ? decoded['installedContentVersion'] as int
            : null,
      };
    } on FormatException {
      // Do not silently discard an unreadable ledger. Treat it as empty;
      // the updater still avoids overwriting existing files and records.
      return <String, dynamic>{
        'knownResourceUuids': <String>[],
        'deletedResourceUuids': <String>[],
        'installedContentVersion': null,
      };
    }
  }

  Set<String> get knownResourceUuids =>
      Set<String>.from(_read()['knownResourceUuids'] as List<String>);

  Set<String> get deletedResourceUuids =>
      Set<String>.from(_read()['deletedResourceUuids'] as List<String>);

  int? get installedContentVersion =>
      _read()['installedContentVersion'] as int?;

  Future<void> recordInstalledContentVersion(int version) async {
    if (version < 1) {
      throw ArgumentError.value(version, 'version', 'Must be positive.');
    }
    final data = _read();
    await _write(
      knownResourceUuids:
          Set<String>.from(data['knownResourceUuids'] as List<String>),
      deletedResourceUuids:
          Set<String>.from(data['deletedResourceUuids'] as List<String>),
      installedContentVersion: version,
    );
  }

  Future<void> registerBundledResources(Iterable<String> uuids) async {
    final data = _read();
    final known = Set<String>.from(data['knownResourceUuids'] as List<String>)
      ..addAll(uuids);

    await _write(
      knownResourceUuids: known,
      deletedResourceUuids:
          Set<String>.from(data['deletedResourceUuids'] as List<String>),
      installedContentVersion: data['installedContentVersion'] as int?,
    );
  }

  Future<bool> recordDeletionIfStarter(String uuid) async {
    final data = _read();
    final known = Set<String>.from(data['knownResourceUuids'] as List<String>);
    if (!known.contains(uuid)) return false;

    final deleted =
        Set<String>.from(data['deletedResourceUuids'] as List<String>)
          ..add(uuid);

    await _write(
      knownResourceUuids: known,
      deletedResourceUuids: deleted,
      installedContentVersion: data['installedContentVersion'] as int?,
    );
    return true;
  }

  Future<void> _write({
    required Set<String> knownResourceUuids,
    required Set<String> deletedResourceUuids,
    int? installedContentVersion,
  }) async {
    await _preferences.setString(
      storageKey,
      jsonEncode(<String, dynamic>{
        'knownResourceUuids': knownResourceUuids.toList()..sort(),
        'deletedResourceUuids': deletedResourceUuids.toList()..sort(),
        if (installedContentVersion != null)
          'installedContentVersion': installedContentVersion,
      }),
    );
  }
}
