import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches and validates published content metadata without applying updates.
class RemoteContentManifestChecker {
  RemoteContentManifestChecker({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<RemoteContentManifestCheckResult> check({
    required Uri manifestUri,
    required int? installedContentVersion,
  }) async {
    if (!manifestUri.hasScheme ||
        (manifestUri.scheme != 'https' && manifestUri.scheme != 'http') ||
        manifestUri.host.isEmpty) {
      throw const RemoteContentManifestException(
        'The manifest URL must be a valid HTTP or HTTPS URL.',
      );
    }

    final http.Response response;
    try {
      response = await _client.get(
        manifestUri,
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const RemoteContentManifestException(
        'Could not reach the content update server.',
      );
    }

    if (response.statusCode != 200) {
      throw RemoteContentManifestException(
        'The content server returned HTTP ${response.statusCode}.',
      );
    }

    final Map<String, dynamic> manifest;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }
      manifest = decoded;
    } catch (_) {
      throw const RemoteContentManifestException(
        'The content manifest is not valid JSON.',
      );
    }

    validateManifest(manifest);

    final contentVersion = manifest['contentVersion'] as int;
    return RemoteContentManifestCheckResult(
      remoteContentVersion: contentVersion,
      installedContentVersion: installedContentVersion,
      updateAvailable: installedContentVersion == null ||
          contentVersion > installedContentVersion,
      taxonomyCount: (manifest['taxonomy'] as List<dynamic>).length,
      resourceCount: (manifest['resources'] as List<dynamic>).length,
      sourcePackUuid: manifest['sourcePackUuid'] as String,
      sourcePackVersion: manifest['sourcePackVersion'] as int,
    );
  }

  /// Validates the shared schema used by remote and embedded manifests.
  static void validateManifest(Map<String, dynamic> manifest) {
    if (manifest['schemaVersion'] != 1) {
      throw const RemoteContentManifestException(
        'Unsupported content manifest schema version.',
      );
    }

    final contentVersion = manifest['contentVersion'];
    final sourcePackVersion = manifest['sourcePackVersion'];
    final sourcePackUuid = manifest['sourcePackUuid'];

    if (contentVersion is! int || contentVersion < 1) {
      throw const RemoteContentManifestException(
        'The manifest has an invalid content version.',
      );
    }
    if (sourcePackVersion is! int || sourcePackVersion < 1) {
      throw const RemoteContentManifestException(
        'The manifest has an invalid source-pack version.',
      );
    }
    if (sourcePackUuid is! String || !_isUuid(sourcePackUuid)) {
      throw const RemoteContentManifestException(
        'The manifest has an invalid source-pack UUID.',
      );
    }

    final taxonomy = manifest['taxonomy'];
    final resources = manifest['resources'];
    if (taxonomy is! List || resources is! List) {
      throw const RemoteContentManifestException(
        'The manifest must contain taxonomy and resource lists.',
      );
    }

    final taxonomyUuids = <String>{};
    for (final entry in taxonomy) {
      if (entry is! Map ||
          entry['uuid'] is! String ||
          !_isUuid(entry['uuid'] as String) ||
          entry['sha256'] is! String ||
          !_isSha256(entry['sha256'] as String)) {
        throw const RemoteContentManifestException(
          'The manifest contains an invalid taxonomy entry.',
        );
      }
      if (!taxonomyUuids.add(entry['uuid'] as String)) {
        throw const RemoteContentManifestException(
          'The manifest contains duplicate taxonomy UUIDs.',
        );
      }
    }

    final resourceUuids = <String>{};
    for (final entry in resources) {
      if (entry is! Map ||
          entry['uuid'] is! String ||
          !_isUuid(entry['uuid'] as String) ||
          entry['topicUuid'] is! String ||
          !_isUuid(entry['topicUuid'] as String) ||
          entry['title'] is! String ||
          (entry['title'] as String).trim().isEmpty ||
          entry['archivePath'] is! String ||
          !_isSafeArchivePath(entry['archivePath'] as String) ||
          entry['fileSizeBytes'] is! int ||
          (entry['fileSizeBytes'] as int) < 1 ||
          entry['sha256'] is! String ||
          !_isSha256(entry['sha256'] as String)) {
        throw const RemoteContentManifestException(
          'The manifest contains an invalid resource entry.',
        );
      }
      final uuid = entry['uuid'] as String;
      final archivePath = entry['archivePath'] as String;
      final expectedPdfPath = 'resources/pdfs/$uuid.pdf';
      final expectedHtmlPath = 'resources/html_lessons/$uuid.zip';

      if (archivePath.toLowerCase() != expectedPdfPath.toLowerCase() &&
          archivePath.toLowerCase() != expectedHtmlPath.toLowerCase()) {
        throw const RemoteContentManifestException(
          'The resource archive path does not match its UUID.',
        );
      }

      if (!resourceUuids.add(uuid.toLowerCase())) {
        throw const RemoteContentManifestException(
          'The manifest contains duplicate resource UUIDs.',
        );
      }
    }
  }

  static bool _isUuid(String value) => RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      ).hasMatch(value);

  static bool _isSha256(String value) =>
      RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value);

  static bool _isSafeArchivePath(String value) {
    if (value.contains(r'\') ||
        value.contains('..') ||
        value.startsWith('/') ||
        value.trim() != value) {
      return false;
    }

    final pdfPath = RegExp(
      r'^resources/pdfs/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\.pdf$',
    );
    final htmlLessonPath = RegExp(
      r'^resources/html_lessons/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\.zip$',
    );

    return pdfPath.hasMatch(value) || htmlLessonPath.hasMatch(value);
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}

class RemoteContentManifestCheckResult {
  const RemoteContentManifestCheckResult({
    required this.remoteContentVersion,
    required this.installedContentVersion,
    required this.updateAvailable,
    required this.taxonomyCount,
    required this.resourceCount,
    required this.sourcePackUuid,
    required this.sourcePackVersion,
  });

  final int remoteContentVersion;
  final int? installedContentVersion;
  final bool updateAvailable;
  final int taxonomyCount;
  final int resourceCount;
  final String sourcePackUuid;
  final int sourcePackVersion;
}

class RemoteContentManifestException implements Exception {
  const RemoteContentManifestException(this.message);

  final String message;

  @override
  String toString() => message;
}
