import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../data/topic_packages/models/topic_package.dart';
import '../../data/topic_packages/topic_package_file_picker.dart';
import '../../data/topic_packages/topic_package_loader.dart';

/// Debug-only, read-only preview of a structurally valid topic package.
class TopicPackagePreviewScreen extends StatefulWidget {
  const TopicPackagePreviewScreen({super.key});

  @override
  State<TopicPackagePreviewScreen> createState() =>
      _TopicPackagePreviewScreenState();
}

class _TopicPackagePreviewScreenState
    extends State<TopicPackagePreviewScreen> {
  final TopicPackageFilePicker _filePicker = const TopicPackageFilePicker();

  TopicPackage? _package;
  String? _error;
  bool _isLoading = false;

  Future<void> _selectPackage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final package = await _filePicker.pickAndLoad();
      if (!mounted) return;

      if (package != null) {
        setState(() => _package = package);
      }
    } on TopicPackageLoadException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _package = null;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _package = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not open the selected file: $error';
        _package = null;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('This preview is available in debug builds.')),
      );
    }

    final theme = Theme.of(context);
    final package = _package;

    return Scaffold(
      appBar: AppBar(title: const Text('Topic package preview')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.fact_check_outlined, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Preview a topic package',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a JSON package to check its structure and inspect '
                    'its metadata. This preview does not import or save it.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _selectPackage,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_open_outlined),
                    label: Text(
                      _isLoading ? 'Checking package…' : 'Choose JSON package',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Package could not be validated',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(_error!),
                  ],
                ),
              ),
            ),
          ],
          if (package != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Structural validation passed',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This confirms structural checks only. It does not '
                      'verify clinical accuracy or approve publication.',
                    ),
                    const Divider(height: 24),
                    _detail('Title', package.topic.title),
                    _detail('Topic ID', package.topic.id),
                    _detail('Specialty', package.topic.specialty),
                    _detail('Schema version', package.schemaVersion),
                    _detail(
                      'Content version',
                      package.topic.contentVersion.toString(),
                    ),
                    _detail('Review status', package.topic.reviewStatus),
                    _detail('Pages', package.pages.length.toString()),
                    _detail('Sources', package.sources.length.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Page outline', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (var i = 0; i < package.pages.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text('${i + 1}'),
                        ),
                        title: Text(package.pages[i].title),
                        subtitle: Text(
                          '${package.pages[i].type} · '
                          '${package.pages[i].blocks.length} block(s)',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Source summary', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final source in package.sources)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.source_outlined),
                        title: Text(
                          _sourceText(source.rawJson['title']) ??
                              source.id,
                        ),
                        subtitle: Text(
                          'Type: ${_sourceText(source.rawJson['sourceType']) ?? 'Not specified'}'
                          ' · Status: ${_sourceText(source.rawJson['status']) ?? 'Not specified'}',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  String? _sourceText(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }
}
