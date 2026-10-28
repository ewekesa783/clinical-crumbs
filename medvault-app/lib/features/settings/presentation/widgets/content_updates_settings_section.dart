import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injector.dart';
import '../../../../features/library/data/bootstrap/starter_content_ledger.dart';
import '../../../../features/library/data/bootstrap/starter_library_initializer.dart';
import '../../../../features/library/data/updates/remote_content_update_service.dart';

class ContentUpdatesSettingsSection extends ConsumerStatefulWidget {
  const ContentUpdatesSettingsSection({super.key});

  @override
  ConsumerState<ContentUpdatesSettingsSection> createState() =>
      _ContentUpdatesSettingsSectionState();
}

class _ContentUpdatesSettingsSectionState
    extends ConsumerState<ContentUpdatesSettingsSection> {
  static const _manifestUrlKey = 'clinical_crumbs_content_manifest_url';
  static const _releaseUrlKey = 'clinical_crumbs_content_release_url';

  final _manifestController = TextEditingController();
  final _releaseController = TextEditingController();

  bool _busy = false;
  bool _advancedExpanded = false;
  String? _status;
  bool? _updateAvailable;
  int? _installedVersion;
  int? _remoteVersion;

  @override
  void initState() {
    super.initState();
    _loadSavedUrls();
  }

  Future<void> _loadSavedUrls() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    _manifestController.text = preferences.getString(_manifestUrlKey) ?? '';
    _releaseController.text = preferences.getString(_releaseUrlKey) ?? '';
    setState(() {});
  }

  Future<RemoteContentUpdateService> _createService(
    SharedPreferences preferences,
  ) async {
    final isar = await ref.read(appDatabaseProvider.future);
    final syncMetadataFactory =
        await ref.read(syncMetadataFactoryProvider.future);
    final clock = ref.read(clockProvider);
    final fileStorage = ref.read(learningResourceFileStorageProvider);

    final initializer = StarterLibraryInitializer(
      isar: isar,
      fileStorage: fileStorage,
      preferences: preferences,
      createSyncMetadata: syncMetadataFactory.call,
      now: clock.now,
    );

    return RemoteContentUpdateService(
      preferences: preferences,
      initializer: initializer,
    );
  }

  Future<void> _saveUrls(SharedPreferences preferences) async {
    await preferences.setString(
        _manifestUrlKey, _manifestController.text.trim());
    await preferences.setString(_releaseUrlKey, _releaseController.text.trim());
  }

  Future<void> _checkForUpdate() async {
    final manifestText = _manifestController.text.trim();
    final manifestUri = Uri.tryParse(manifestText);
    if (manifestUri == null || manifestUri.host.isEmpty) {
      _showStatus('Enter a valid content manifest URL.');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Checking for published content…';
      _updateAvailable = null;
    });

    RemoteContentUpdateService? service;
    try {
      final preferences = await SharedPreferences.getInstance();
      await _saveUrls(preferences);
      service = await _createService(preferences);
      final result = await service.checkForUpdate(manifestUri: manifestUri);
      if (!mounted) return;

      setState(() {
        _installedVersion = result.installedContentVersion;
        _remoteVersion = result.remoteContentVersion;
        _updateAvailable = result.updateAvailable;
        _status = result.updateAvailable
            ? 'A content update is available.'
            : 'Your content is up to date.';
      });
    } catch (_) {
      _showStatus(
        'Could not check for updates. Verify the manifest URL and connection.',
      );
    } finally {
      service?.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadUpdate() async {
    final releaseText = _releaseController.text.trim();
    final releaseUri = Uri.tryParse(releaseText);
    if (releaseUri == null || releaseUri.host.isEmpty) {
      _showStatus('Enter a valid release descriptor URL.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Install content update?'),
        content: const Text(
          'The app will download and validate the published content package. '
          'Existing personal data and reading progress should be preserved. '
          'Continue only if you trust this release source.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Download and apply'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _status = 'Downloading and validating content…';
    });

    RemoteContentUpdateService? service;
    try {
      final preferences = await SharedPreferences.getInstance();
      await _saveUrls(preferences);
      service = await _createService(preferences);
      final applied = await service.downloadAndApply(releaseUri: releaseUri);
      if (!mounted) return;

      setState(() {
        if (applied) {
          _updateAvailable = false;
          _installedVersion =
              StarterContentLedger(preferences).installedContentVersion;
          _status = 'Content update installed successfully.';
        } else {
          _status =
              'The update was not applied. It may be current, unavailable, or invalid.';
        }
      });
    } catch (_) {
      _showStatus(
          'Unable to apply the update. Your library was not confirmed updated.');
    } finally {
      service?.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showStatus(String message) {
    if (!mounted) return;
    setState(() => _status = message);
  }

  @override
  void dispose() {
    _manifestController.dispose();
    _releaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasVersion = _installedVersion != null || _remoteVersion != null;
    final showDownload = _updateAvailable == true;
    final statusColor = _status == null
        ? null
        : (_status!.toLowerCase().contains('could not') ||
                _status!.toLowerCase().contains('unable') ||
                _status!.toLowerCase().contains('not applied') ||
                _status!.toLowerCase().contains('valid'))
            ? colors.error
            : _updateAvailable == true
                ? colors.primary
                : colors.onSurfaceVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.system_update_alt,
                  color: colors.primary,
                  size: 25,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content updates',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Keep your learning library current.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_updateAvailable == false)
                  Icon(Icons.check_circle_outline,
                      color: colors.primary, size: 22)
                else if (showDownload)
                  Icon(Icons.system_update, color: colors.primary, size: 22),
              ],
            ),
            if (hasVersion) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _VersionLabel(
                        label: 'Installed',
                        value: _installedVersion?.toString() ?? '—',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: colors.outlineVariant,
                    ),
                    Expanded(
                      child: _VersionLabel(
                        label: 'Published',
                        value: _remoteVersion?.toString() ?? '—',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_status != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _busy
                        ? Icons.sync
                        : _updateAvailable == true
                            ? Icons.info_outline
                            : _status!.toLowerCase().contains('successfully') ||
                                    _status!.toLowerCase().contains('up to date')
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _status!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: statusColor),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy
                    ? null
                    : showDownload
                        ? _downloadUpdate
                        : _checkForUpdate,
                icon: Icon(showDownload ? Icons.download : Icons.refresh),
                label: Text(
                  showDownload ? 'Download and apply update' : 'Check for updates',
                ),
              ),
            ),
            const SizedBox(height: 2),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              initiallyExpanded: _advancedExpanded,
              onExpansionChanged: (expanded) {
                setState(() => _advancedExpanded = expanded);
              },
              leading: Icon(
                Icons.tune,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              title: const Text('Advanced settings'),
              subtitle: const Text('Content source URLs'),
              children: [
                TextField(
                  controller: _manifestController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Content manifest URL',
                    hintText: 'https://your-host/content-manifest.json',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _releaseController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Release descriptor URL',
                    hintText: 'https://your-host/release.json',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Updates are only installed when you choose to download and apply them.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionLabel extends StatelessWidget {
  const _VersionLabel({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'v$value',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
