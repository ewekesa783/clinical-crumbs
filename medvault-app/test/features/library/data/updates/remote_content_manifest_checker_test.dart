import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medvault_app/features/library/data/updates/remote_content_manifest_checker.dart';

void main() {
  const sourcePackUuid = '651ccab1-e94e-416a-b8c4-59c6b0b75171';
  const topicUuid = '10000000-0000-5000-8000-000000000001';
  const resourceUuid = '1a7cb417-6aae-4aa6-830a-d30d08bef391';
  const hash =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  Map<String, dynamic> manifest({
    int schemaVersion = 1,
    int contentVersion = 2,
    List<dynamic>? taxonomy,
    List<dynamic>? resources,
  }) =>
      {
        'schemaVersion': schemaVersion,
        'contentVersion': contentVersion,
        'sourcePackUuid': sourcePackUuid,
        'sourcePackVersion': 1,
        'taxonomy': taxonomy ??
            [
              {'uuid': topicUuid, 'sha256': hash},
            ],
        'resources': resources ??
            [
              {
                'uuid': resourceUuid,
                'topicUuid': topicUuid,
                'title': 'Example PDF',
                'archivePath': 'resources/pdfs/$resourceUuid.pdf',
                'fileSizeBytes': 1234,
                'sha256': hash,
              },
            ],
      };

  RemoteContentManifestChecker checkerWith(
    http.Response response,
  ) =>
      RemoteContentManifestChecker(
        client: MockClient((_) async => response),
      );

  const uri = 'http://127.0.0.1:8000/content-manifest.json';

  group('RemoteContentManifestChecker', () {
    test('reports a newer version without applying it', () async {
      final checker = checkerWith(
        http.Response(jsonEncode(manifest()), 200),
      );

      final result = await checker.check(
        manifestUri: Uri.parse(uri),
        installedContentVersion: 1,
      );

      expect(result.updateAvailable, isTrue);
      expect(result.remoteContentVersion, 2);
      expect(result.installedContentVersion, 1);
      expect(result.taxonomyCount, 1);
      expect(result.resourceCount, 1);
      expect(result.sourcePackUuid, sourcePackUuid);
      expect(result.sourcePackVersion, 1);
    });

    test('same version is not an update', () async {
      final checker = checkerWith(
        http.Response(jsonEncode(manifest(contentVersion: 2)), 200),
      );

      final result = await checker.check(
        manifestUri: Uri.parse(uri),
        installedContentVersion: 2,
      );

      expect(result.updateAvailable, isFalse);
    });

    test('older version is not an update', () async {
      final checker = checkerWith(
        http.Response(jsonEncode(manifest(contentVersion: 1)), 200),
      );

      final result = await checker.check(
        manifestUri: Uri.parse(uri),
        installedContentVersion: 2,
      );

      expect(result.updateAvailable, isFalse);
    });

    test('unknown installed version offers an update', () async {
      final checker = checkerWith(
        http.Response(jsonEncode(manifest()), 200),
      );

      final result = await checker.check(
        manifestUri: Uri.parse(uri),
        installedContentVersion: null,
      );

      expect(result.updateAvailable, isTrue);
    });

    test('rejects unsupported schema versions', () async {
      final checker = checkerWith(
        http.Response(
          jsonEncode(manifest(schemaVersion: 99)),
          200,
        ),
      );

      expect(
        () => checker.check(
          manifestUri: Uri.parse(uri),
          installedContentVersion: 1,
        ),
        throwsA(isA<RemoteContentManifestException>()),
      );
    });

    test('rejects invalid JSON', () async {
      final checker = checkerWith(http.Response('{broken', 200));

      expect(
        () => checker.check(
          manifestUri: Uri.parse(uri),
          installedContentVersion: 1,
        ),
        throwsA(isA<RemoteContentManifestException>()),
      );
    });

    test('rejects duplicate taxonomy UUIDs', () async {
      final checker = checkerWith(
        http.Response(
          jsonEncode(
            manifest(
              taxonomy: [
                {'uuid': topicUuid, 'sha256': hash},
                {'uuid': topicUuid, 'sha256': hash},
              ],
            ),
          ),
          200,
        ),
      );

      expect(
        () => checker.check(
          manifestUri: Uri.parse(uri),
          installedContentVersion: 1,
        ),
        throwsA(isA<RemoteContentManifestException>()),
      );
    });

    test('rejects duplicate resource UUIDs', () async {
      final resource = {
        'uuid': resourceUuid,
        'topicUuid': topicUuid,
        'title': 'Example PDF',
        'archivePath': 'resources/pdfs/$resourceUuid.pdf',
        'fileSizeBytes': 1234,
        'sha256': hash,
      };
      final checker = checkerWith(
        http.Response(
          jsonEncode(manifest(resources: [resource, resource])),
          200,
        ),
      );

      expect(
        () => checker.check(
          manifestUri: Uri.parse(uri),
          installedContentVersion: 1,
        ),
        throwsA(isA<RemoteContentManifestException>()),
      );
    });

    test('accepts HTML lesson ZIP archive paths', () async {
      final checker = checkerWith(
        http.Response(
          jsonEncode(
            manifest(
              resources: [
                {
                  'uuid': resourceUuid,
                  'topicUuid': topicUuid,
                  'title': 'Example HTML Lesson',
                  'archivePath': 'resources/html_lessons/$resourceUuid.zip',
                  'fileSizeBytes': 1234,
                  'sha256': hash,
                },
              ],
            ),
          ),
          200,
        ),
      );

      final result = await checker.check(
        manifestUri: Uri.parse(uri),
        installedContentVersion: 1,
      );

      expect(result.resourceCount, 1);
      checker.close();
    });

    test('rejects archive paths whose UUID does not match the resource',
        () async {
      final checker = checkerWith(
        http.Response(
          jsonEncode(
            manifest(
              resources: [
                {
                  'uuid': resourceUuid,
                  'topicUuid': topicUuid,
                  'title': 'Example HTML Lesson',
                  'archivePath':
                      'resources/html_lessons/00000000-0000-4000-8000-000000000000.zip',
                  'fileSizeBytes': 1234,
                  'sha256': hash,
                },
              ],
            ),
          ),
          200,
        ),
      );

      expect(
        () => checker.check(
          manifestUri: Uri.parse(uri),
          installedContentVersion: 1,
        ),
        throwsA(isA<RemoteContentManifestException>()),
      );
      checker.close();
    });

    test('rejects duplicate resource UUIDs with different letter casing',
        () async {
      final resource = {
        'uuid': resourceUuid,
        'topicUuid': topicUuid,
        'title': 'Example PDF',
        'archivePath': 'resources/pdfs/$resourceUuid.pdf',
        'fileSizeBytes': 1234,
        'sha256': hash,
      };
      final duplicate = {
        ...resource,
        'uuid': resourceUuid.toUpperCase(),
        'archivePath': 'resources/pdfs/${resourceUuid.toUpperCase()}.pdf',
      };
      final checker = checkerWith(
        http.Response(
          jsonEncode(manifest(resources: [resource, duplicate])),
          200,
        ),
      );

      expect(
        () => checker.check(
          manifestUri: Uri.parse(uri),
          installedContentVersion: 1,
        ),
        throwsA(isA<RemoteContentManifestException>()),
      );
      checker.close();
    });

    test('rejects unsafe archive paths', () async {
      final checker = checkerWith(
        http.Response(
          jsonEncode(
            manifest(
              resources: [
                {
                  'uuid': resourceUuid,
                  'topicUuid': topicUuid,
                  'title': 'Example PDF',
                  'archivePath': 'resources/pdfs/../../outside.pdf',
                  'fileSizeBytes': 1234,
                  'sha256': hash,
                },
              ],
            ),
          ),
          200,
        ),
      );

      expect(
        () => checker.check(
          manifestUri: Uri.parse(uri),
          installedContentVersion: 1,
        ),
        throwsA(isA<RemoteContentManifestException>()),
      );
    });

    test('rejects non-success HTTP responses', () async {
      final checker = checkerWith(http.Response('unavailable', 503));

      expect(
        () => checker.check(
          manifestUri: Uri.parse(uri),
          installedContentVersion: 1,
        ),
        throwsA(isA<RemoteContentManifestException>()),
      );
    });

    test('rejects non-HTTP manifest URLs', () async {
      final checker = checkerWith(http.Response('{}', 200));

      expect(
        () => checker.check(
          manifestUri: Uri.parse('file:///tmp/content-manifest.json'),
          installedContentVersion: 1,
        ),
        throwsA(isA<RemoteContentManifestException>()),
      );
    });
  });
}
