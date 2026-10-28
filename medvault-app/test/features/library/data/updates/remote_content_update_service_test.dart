import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medvault_app/features/library/data/bootstrap/starter_content_ledger.dart';
import 'package:medvault_app/features/library/data/updates/remote_content_manifest_checker.dart';
import 'package:medvault_app/features/library/data/updates/remote_content_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('checks remote version against the version saved in the ledger',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await StarterContentLedger(preferences).recordInstalledContentVersion(1);

    final manifest = {
      'schemaVersion': 1,
      'contentVersion': 2,
      'sourcePackUuid': '651ccab1-e94e-416a-b8c4-59c6b0b75171',
      'sourcePackVersion': 1,
      'taxonomy': [
        {
          'uuid': '11111111-1111-4111-8111-111111111111',
          'sha256':
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        }
      ],
      'resources': [
        {
          'uuid': '22222222-2222-4222-8222-222222222222',
          'topicUuid': '11111111-1111-4111-8111-111111111111',
          'title': 'Test PDF',
          'archivePath':
              'resources/pdfs/22222222-2222-4222-8222-222222222222.pdf',
          'fileSizeBytes': 10,
          'sha256':
              'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        }
      ],
    };

    final client = MockClient((request) async {
      expect(request.url.path, '/content-manifest.json');
      return http.Response(jsonEncode(manifest), 200);
    });
    final checker = RemoteContentManifestChecker(client: client);
    final service = RemoteContentUpdateService(
      preferences: preferences,
      checker: checker,
    );

    try {
      final result = await service.checkForUpdate(
        manifestUri: Uri.parse('http://127.0.0.1:8765/content-manifest.json'),
      );

      expect(result.installedContentVersion, 1);
      expect(result.remoteContentVersion, 2);
      expect(result.updateAvailable, isTrue);
    } finally {
      service.close();
      checker.close();
      client.close();
    }
  });
}
