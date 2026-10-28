import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/library/data/updates/remote_content_manifest_checker.dart';

void main() {
  final manifestUrl = Platform.environment['CLINICAL_CRUMBS_MANIFEST_URL'];

  test(
    'fetches and validates the real laptop-hosted manifest',
    () async {
      final checker = RemoteContentManifestChecker();
      try {
        final result = await checker.check(
          manifestUri: Uri.parse(manifestUrl!),
          installedContentVersion: null,
        );

        expect(result.remoteContentVersion, 1);
        expect(result.updateAvailable, isTrue);
        expect(result.taxonomyCount, 380);
        expect(result.resourceCount, 12);
        expect(
          result.sourcePackUuid,
          '651ccab1-e94e-416a-b8c4-59c6b0b75171',
        );
      } finally {
        checker.close();
      }
    },
    skip: manifestUrl == null || manifestUrl.trim().isEmpty
        ? 'Set CLINICAL_CRUMBS_MANIFEST_URL to run the local-server integration test.'
        : false,
  );
}
