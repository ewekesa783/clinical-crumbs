import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap/starter_content_ledger.dart';
import '../bootstrap/starter_library_initializer.dart';
import 'remote_content_manifest_checker.dart';

/// Downloads and explicitly applies a verified published content release.
///
/// A release descriptor contains:
/// {
///   "schemaVersion": 1,
///   "contentVersion": 1,
///   "archiveUrl": "https://example.org/content.zip",
///   "archiveSha256": "<64 hexadecimal characters>",
///   "manifest": { ...content-manifest.json... }
/// }
class RemoteContentReleaseDownloader {
  RemoteContentReleaseDownloader({
    required SharedPreferences preferences,
    required StarterLibraryInitializer initializer,
    http.Client? client,
  })  : _preferences = preferences,
        _initializer = initializer,
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  static const int maxArchiveBytes = 20 * 1024 * 1024;
  static const int maxDescriptorBytes = 1024 * 1024;

  final SharedPreferences _preferences;
  final StarterLibraryInitializer _initializer;
  final http.Client _client;
  final bool _ownsClient;

  /// Returns false when no newer release is available or validation fails.
  ///
  /// No download is attempted until the descriptor has been validated.
  /// The installer is called only after the archive checksum and embedded
  /// manifest have both been verified.
  Future<bool> downloadAndApply({required Uri releaseUri}) async {
    try {
      _validateNetworkUri(releaseUri);

      final descriptorBytes = await _getBytes(
        releaseUri,
        maxBytes: maxDescriptorBytes,
        accept: 'application/json',
      );
      final decoded = jsonDecode(utf8.decode(descriptorBytes));
      if (decoded is! Map<String, dynamic>) return false;

      final descriptor = decoded;
      if (descriptor['schemaVersion'] != 1) return false;

      final contentVersion = descriptor['contentVersion'];
      final archiveUrl = descriptor['archiveUrl'];
      final archiveSha256 = descriptor['archiveSha256'];
      final manifest = descriptor['manifest'];

      if (contentVersion is! int ||
          contentVersion < 1 ||
          archiveUrl is! String ||
          archiveSha256 is! String ||
          !_isSha256(archiveSha256) ||
          manifest is! Map<String, dynamic>) {
        return false;
      }

      RemoteContentManifestChecker.validateManifest(manifest);
      if (manifest['contentVersion'] != contentVersion) return false;

      final installedVersion =
          StarterContentLedger(_preferences).installedContentVersion;
      if (installedVersion != null && contentVersion <= installedVersion) {
        return false;
      }

      final archiveUri = Uri.tryParse(archiveUrl);
      if (archiveUri == null) return false;
      _validateNetworkUri(archiveUri);

      final archiveBytes = await _getBytes(
        archiveUri,
        maxBytes: maxArchiveBytes,
        accept: 'application/zip, application/octet-stream',
      );

      final actualSha256 = sha256.convert(archiveBytes).toString();
      if (actualSha256.toLowerCase() != archiveSha256.toLowerCase()) {
        return false;
      }

      return _initializer.updateContentFromArchive(
        Uint8List.fromList(archiveBytes),
        expectedManifest: manifest,
      );
    } on RemoteContentManifestException {
      return false;
    } on FormatException {
      return false;
    } on http.ClientException {
      return false;
    } on Exception {
      return false;
    }
  }

  Future<List<int>> _getBytes(
    Uri uri, {
    required int maxBytes,
    required String accept,
  }) async {
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers['Accept'] = accept;
    final response =
        await _client.send(request).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw const RemoteContentManifestException(
        'The content server did not return HTTP 200.',
      );
    }

    final declaredLength = response.contentLength;
    if (declaredLength != null && declaredLength > maxBytes) {
      throw const RemoteContentManifestException(
        'The downloaded file exceeds the permitted size.',
      );
    }

    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 20),
    )) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const RemoteContentManifestException(
          'The downloaded file exceeds the permitted size.',
        );
      }
      bytes.addAll(chunk);
    }
    return bytes;
  }

  void _validateNetworkUri(Uri uri) {
    if (!uri.hasScheme || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw const RemoteContentManifestException(
        'The release URL is invalid.',
      );
    }

    if (uri.scheme == 'https') return;

    final host = uri.host.toLowerCase();
    final isLoopback = host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host == '[::1]';

    if (uri.scheme == 'http' && isLoopback) return;

    // Permit HTTP only for the explicitly configured laptop content server.
    // All other non-loopback content servers must use HTTPS.
    if (uri.scheme == 'http' && host == '192.168.0.103') return;

    throw const RemoteContentManifestException(
      'Content servers must use HTTPS, except loopback and the configured laptop server.',
    );
  }

  bool _isSha256(String value) => RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value);

  void close() {
    if (_ownsClient) _client.close();
  }
}
