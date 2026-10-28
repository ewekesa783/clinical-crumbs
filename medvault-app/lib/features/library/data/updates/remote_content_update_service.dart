import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap/starter_content_ledger.dart';
import '../bootstrap/starter_library_initializer.dart';
import 'remote_content_release_downloader.dart';
import 'remote_content_manifest_checker.dart';

/// Checks published content against the installed version without applying it.
class RemoteContentUpdateService {
  RemoteContentUpdateService({
    required SharedPreferences preferences,
    RemoteContentManifestChecker? checker,
    RemoteContentReleaseDownloader? downloader,
    StarterLibraryInitializer? initializer,
  })  : _preferences = preferences,
        _checker = checker ?? RemoteContentManifestChecker(),
        _ownsChecker = checker == null,
        _downloader = downloader ??
            (initializer == null
                ? null
                : RemoteContentReleaseDownloader(
                    preferences: preferences,
                    initializer: initializer,
                  )),
        _ownsDownloader = downloader == null && initializer != null;

  final SharedPreferences _preferences;
  final RemoteContentManifestChecker _checker;
  final bool _ownsChecker;
  final RemoteContentReleaseDownloader? _downloader;
  final bool _ownsDownloader;

  Future<RemoteContentManifestCheckResult> checkForUpdate({
    required Uri manifestUri,
  }) {
    final installedVersion =
        StarterContentLedger(_preferences).installedContentVersion;

    return _checker.check(
      manifestUri: manifestUri,
      installedContentVersion: installedVersion,
    );
  }

  /// Downloads and applies a newer release only when explicitly requested.
  ///
  /// Returns false if no downloader was configured or validation fails.
  Future<bool> downloadAndApply({required Uri releaseUri}) async {
    final downloader = _downloader;
    if (downloader == null) return false;
    return downloader.downloadAndApply(releaseUri: releaseUri);
  }

  void close() {
    if (_ownsChecker) {
      _checker.close();
    }
    if (_ownsDownloader) {
      _downloader?.close();
    }
  }
}
