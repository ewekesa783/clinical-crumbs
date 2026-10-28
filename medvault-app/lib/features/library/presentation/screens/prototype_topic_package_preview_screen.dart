import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../data/topic_packages/prototype_lesson_archive_reader.dart';
import '../../data/topic_packages/prototype_html_lesson_archive_reader.dart';
import 'prototype_lesson_renderer.dart';
import 'prototype_html_lesson_viewer.dart';

/// Read-only preview for the newer Clinical Crumbs lesson prototype format.
///
/// This is intentionally separate from the original starter-pack schema.
/// It never imports content into the library or writes to app storage.
class PrototypeTopicPackagePreviewScreen extends StatefulWidget {
  const PrototypeTopicPackagePreviewScreen({super.key});

  @override
  State<PrototypeTopicPackagePreviewScreen> createState() =>
      _PrototypeTopicPackagePreviewScreenState();
}

class _PrototypeTopicPackagePreviewScreenState
    extends State<PrototypeTopicPackagePreviewScreen> {
  Map<String, dynamic>? _package;
  String? _htmlDocument;
  Map<String, Uint8List> _assets = {};
  String? _error;
  bool _isLoading = false;

  Future<void> _selectPackage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['html', 'htm', 'json', 'zip'],
        allowMultiple: false,
        withData: true,
      );
      if (!mounted) return;
      if (selection == null) return;

      final selectedFile = selection.files.single;
      final bytes = selectedFile.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException(
          'The selected file has no readable contents.',
        );
      }

      final extension = selectedFile.extension?.toLowerCase();
      Map<String, dynamic>? data;
      Map<String, Uint8List> assets = {};
      String? htmlDocument;

      if (extension == 'zip') {
        try {
          final archive = const PrototypeLessonArchiveReader().read(bytes);
          data = archive.lesson;
          assets = archive.assets;
        } on FormatException catch (error) {
          if (error.message !=
              'The ZIP must contain lesson.json or one lesson JSON under content/.') {
            rethrow;
          }

          htmlDocument =
              const PrototypeHtmlLessonArchiveReader().read(bytes).html;
        }
      } else if (extension == 'html' || extension == 'htm') {
        final html = utf8.decode(bytes);
        final normalized = html.trimLeft().toLowerCase();
        if (!normalized.contains('<html') ||
            !normalized.contains('</html>')) {
          throw const FormatException(
            'The selected file must contain a complete HTML document.',
          );
        }
        htmlDocument = html;
      } else if (extension == 'json') {
        final Object? decoded;
        try {
          decoded = jsonDecode(utf8.decode(bytes));
        } on FormatException {
          rethrow;
        }

        if (decoded is! Map) {
          throw const FormatException(
            'The package root must be a JSON object.',
          );
        }

        try {
          data = Map<String, dynamic>.from(decoded);
        } on TypeError {
          throw const FormatException(
            'The package root must contain string keys.',
          );
        }

        final version = data['schema_version'];
        final topicId = data['topic_id'];
        final title = data['title'];
        final pages = data['pages'];

        if (version is! String) {
          throw const FormatException('"schema_version" must be a string.');
        }
        if (topicId is! String || topicId.trim().isEmpty) {
          throw const FormatException('"topic_id" must be a non-empty string.');
        }
        if (title is! String || title.trim().isEmpty) {
          throw const FormatException('"title" must be a non-empty string.');
        }
        if (pages is! List || pages.isEmpty) {
          throw const FormatException('"pages" must be a non-empty array.');
        }

        for (var i = 0; i < pages.length; i++) {
          final page = pages[i];
          if (page is! Map) {
            throw FormatException('pages[$i] must be a JSON object.');
          }
          if (page['id'] is! String ||
              page['type'] is! String ||
              page['title'] is! String) {
            throw FormatException(
              'pages[$i] must contain string fields "id", "type", and "title".',
            );
          }
        }
      } else {
        throw const FormatException('Choose a .json or .zip lesson package.');
      }

      if (mounted) {
        setState(() {
          _package = data;
          _htmlDocument = htmlDocument;
          _assets = assets;
          _error = null;
        });
      }
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _package = null;
        _htmlDocument = null;
        _assets = {};
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not open the selected file: $error';
        _package = null;
        _htmlDocument = null;
        _assets = {};
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
    final data = _package;
    final htmlDocument = _htmlDocument;

    if (htmlDocument != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('HTML lesson preview'),
          actions: [
            TextButton.icon(
              onPressed: _isLoading ? null : _selectPackage,
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: const Text('Change'),
            ),
          ],
        ),
        body: PrototypeHtmlLessonViewer(
          key: ValueKey(htmlDocument.hashCode),
          html: htmlDocument,
          resourceUuid: 'preview-html-${htmlDocument.hashCode}',
        ),
      );
    }

    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prototype lesson preview')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_stories_outlined, size: 32),
                    const SizedBox(height: 12),
                    Text('Preview a prototype lesson',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose an HTML lesson, JSON lesson, or ZIP bundle to preview its designed '
                      'pages and interactions. This preview is read-only: '
                      'it does not import or save anything.',
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
                        _isLoading
                            ? 'Checking package…'
                            : 'Choose HTML, JSON, or ZIP bundle',
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
                      Text('Package could not be previewed',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SelectableText(_error!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final pages = data['pages'] as List? ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Prototype lesson preview')),
      body: Column(
        children: [
          Material(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Structure checks passed · Read-only preview',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isLoading ? null : _selectPackage,
                        icon: const Icon(Icons.folder_open_outlined, size: 18),
                        label: const Text('Change'),
                      ),
                    ],
                  ),
                  Text(
                    '${data['title']}  ·  ${pages.length} pages',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (data['clinical_review_required'] == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        'Clinical review required before publication. '
                        'Structural checks do not verify clinical accuracy.',
                        style: TextStyle(fontSize: 11, height: 1.35),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: PrototypeLessonRenderer(
              lesson: data,
              resourceUuid: 'preview-lesson-${data.hashCode}',
              assets: _assets,
              onChooseAnother: _selectPackage,
            ),
          ),
        ],
      ),
    );
  }
}
