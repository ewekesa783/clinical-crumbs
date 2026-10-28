import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/bootstrap/starter_content_ledger.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/spacing_tokens.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/sync/sync_metadata.dart';
import '../../domain/entities/learning_resource.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/taxonomy_node.dart';
import '../../data/repositories/single_topic_json_importer.dart';
import '../../data/topic_packages/prototype_html_lesson_archive_reader.dart';
import '../../data/topic_packages/prototype_lesson_archive_reader.dart';
import '../providers/taxonomy_browser_provider.dart';

String _topicSlug(String title) => title
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

Future<String?> _promptForTopicName(
  BuildContext context, {
  String? initialTitle,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TopicNameDialog(initialTitle: initialTitle),
  );
}

Future<void> _addTopic(
  BuildContext context,
  WidgetRef ref,
  TaxonomyNode parent,
) async {
  if (!kDebugMode || parent.nodeType != NodeType.system) return;

  final title = await _promptForTopicName(context);
  if (!context.mounted || title == null) return;

  final slug = _topicSlug(title);
  if (slug.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid topic name.')),
    );
    return;
  }

  try {
    final repository = await ref.read(taxonomyRepositoryProvider.future);
    final siblings = await repository.getChildren(parent.uuid);

    if (siblings.any((node) => node.slug == slug)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A topic with that name already exists.')),
      );
      return;
    }

    final now = ref.read(clockProvider).now();
    final uuid = UuidGenerator().call();
    final sortOrder = siblings.fold<int>(
          -1,
          (highest, node) =>
              node.sortOrder > highest ? node.sortOrder : highest,
        ) +
        1;
    final syncFactory = await ref.read(syncMetadataFactoryProvider.future);

    await repository.save(
      TaxonomyNode(
        uuid: uuid,
        parentUuid: parent.uuid,
        path: '${parent.path}/$uuid',
        depth: parent.depth + 1,
        nodeType: NodeType.topic,
        title: title,
        slug: slug,
        sortOrder: sortOrder,
        noteCount: 0,
        isUserCreated: true,
        createdAt: now,
        updatedAt: now,
        sync: syncFactory(),
      ),
    );

    ref.invalidate(taxonomyBrowserProvider(parent.uuid));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Topic added.')),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to add this topic.')),
    );
  }
}

Future<void> _renameTopic(
  BuildContext context,
  WidgetRef ref,
  TaxonomyNode topic,
) async {
  if (!kDebugMode ||
      topic.nodeType != NodeType.topic ||
      topic.parentUuid == null) {
    return;
  }

  final title = await _promptForTopicName(
    context,
    initialTitle: topic.title,
  );
  if (!context.mounted || title == null || title == topic.title) return;

  final slug = _topicSlug(title);
  if (slug.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid topic name.')),
    );
    return;
  }

  try {
    final repository = await ref.read(taxonomyRepositoryProvider.future);
    final siblings = await repository.getChildren(topic.parentUuid!);

    if (siblings.any((node) => node.uuid != topic.uuid && node.slug == slug)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A topic with that name already exists.')),
      );
      return;
    }

    final now = ref.read(clockProvider).now();
    final oldSync = topic.sync;

    await repository.save(
      TaxonomyNode(
        uuid: topic.uuid,
        parentUuid: topic.parentUuid,
        path: topic.path,
        depth: topic.depth,
        nodeType: topic.nodeType,
        title: title,
        slug: slug,
        shortDescription: topic.shortDescription,
        iconKey: topic.iconKey,
        sortOrder: topic.sortOrder,
        noteCount: topic.noteCount,
        curriculumPackUuid: topic.curriculumPackUuid,
        curriculumPackVersion: topic.curriculumPackVersion,
        isUserCreated: topic.isUserCreated,
        createdAt: topic.createdAt,
        updatedAt: now,
        sync: SyncMetadata(
          remoteId: oldSync.remoteId,
          lastModifiedLocal: now,
          lastSyncedAt: oldSync.lastSyncedAt,
          isDirty: true,
          isDeleted: oldSync.isDeleted,
          deviceId: oldSync.deviceId,
          syncRevision: oldSync.syncRevision + 1,
        ),
      ),
    );

    ref.invalidate(taxonomyBrowserProvider(topic.parentUuid!));
    ref.invalidate(taxonomyBrowserProvider(topic.uuid));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Topic renamed.')),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to rename this topic.')),
    );
  }
}

Future<void> _deleteUserCreatedTopic(
  BuildContext context,
  WidgetRef ref,
  TaxonomyNode topic, {
  bool closeCurrentScreen = false,
}) async {
  if (!kDebugMode ||
      topic.nodeType != NodeType.topic ||
      !topic.isUserCreated ||
      topic.parentUuid == null) {
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete topic?'),
      content: Text(
        '“${topic.title}” and everything inside it will be permanently '
        'deleted, including nested topics, detailed notes, bookmarks, '
        'reading history, and imported PDFs. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete topic'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  try {
    final taxonomyRepository =
        await ref.read(taxonomyRepositoryProvider.future);
    final noteRepository = await ref.read(noteRepositoryProvider.future);
    final resourceRepository =
        await ref.read(learningResourceRepositoryProvider.future);
    final libraryService = await ref.read(libraryServiceProvider.future);

    final allNodes = await taxonomyRepository.getAll();
    final nodesByParent = <String, List<TaxonomyNode>>{};
    for (final node in allNodes) {
      final parent = node.parentUuid;
      if (parent != null) {
        nodesByParent.putIfAbsent(parent, () => []).add(node);
      }
    }

    final descendants = <TaxonomyNode>[];
    final pending = <TaxonomyNode>[topic];
    final seen = <String>{};
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (!seen.add(current.uuid)) continue;
      descendants.add(current);
      pending.addAll(nodesByParent[current.uuid] ?? const <TaxonomyNode>[]);
    }

    final topicUuids = descendants.map((node) => node.uuid).toSet();
    final notes = await noteRepository.getAll();
    final resources = await resourceRepository.getAll();
    final preferences = await SharedPreferences.getInstance();
    final ledger = StarterContentLedger(preferences);
    final storage = ref.read(learningResourceFileStorageProvider);

    for (final note in notes.where(
      (note) => topicUuids.contains(note.topicUuid),
    )) {
      await libraryService.deleteNote(note.uuid);
      await libraryService.removeHistoryEntry(note.uuid);
    }

    for (final resource in resources.where(
      (resource) => topicUuids.contains(resource.topicUuid),
    )) {
      await ledger.recordDeletionIfStarter(resource.uuid);
      await libraryService.unbookmarkPdf(resource.uuid);
      await libraryService.removeHistoryEntry(resource.uuid);
      if (resource.format == LearningResourceFormat.htmlLesson) {
        await storage.deleteHtmlLessonPackage(resource.relativeFilePath);
      } else {
        await storage.deletePdf(resource.relativeFilePath);
      }
      await resourceRepository.deleteByUuid(resource.uuid);
    }

    descendants.sort((a, b) => b.depth.compareTo(a.depth));
    for (final node in descendants) {
      await taxonomyRepository.deleteByUuid(node.uuid);
    }

    final parentUuid = topic.parentUuid!;
    ref.invalidate(taxonomyBrowserProvider(parentUuid));
    for (final node in descendants) {
      ref.invalidate(taxonomyBrowserProvider(node.uuid));
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“${topic.title}” deleted.')),
    );
    if (closeCurrentScreen && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  } catch (error, stackTrace) {
    debugPrint('Topic deletion failed: $error\n$stackTrace');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The topic could not be fully deleted. Some items may already '
          'have been removed; please check the topic before retrying.',
        ),
      ),
    );
  }
}

Future<void> _importStructuredJsonForTopic(
  BuildContext context,
  WidgetRef ref,
  TaxonomyNode destination,
) async {
  if (!kDebugMode) return;

  try {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (!context.mounted || selection == null) return;

    final file = selection.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to read the selected JSON file.')),
      );
      return;
    }

    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('The JSON root must be an object.');
    }
    final document = Map<String, dynamic>.from(decoded);
    final title = document['title'];
    if (title is! String || title.trim().isEmpty) {
      throw const FormatException('The JSON document needs a title.');
    }

    final rawTopics = document['topics'];
    final topicCount = rawTopics is List ? rawTopics.length : 0;
    final isStandalone =
        (rawTopics == null || rawTopics is! List || rawTopics.isEmpty) &&
            document['sections'] is List &&
            (document['sections'] as List).isNotEmpty;

    final importDescription = isStandalone
        ? 'This creates one topic with one detailed note containing its '
            'sections and points. Existing content will not be overwritten.'
        : 'This creates a parent topic, an Introduction topic, '
            '$topicCount child topic(s) from the JSON, and a note for each '
            'child. Existing content will not be overwritten.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import structured JSON'),
        content: Text(
          'Import "$title" under "${destination.title}".\n\n'
          '$importDescription',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;

    final isar = await ref.read(appDatabaseProvider.future);
    final syncFactory = await ref.read(syncMetadataFactoryProvider.future);
    final clock = ref.read(clockProvider);

    final importer = SingleTopicJsonImporter(
      isar: isar,
      generateUuid: UuidGenerator().call,
      createSyncMetadata: syncFactory.call,
      now: clock.now,
    );

    final result = await importer.importDocument(
      destination: destination,
      document: document,
    );

    if (!context.mounted) return;
    ref.invalidate(taxonomyBrowserProvider(destination.uuid));
    final successMessage = isStandalone
        ? 'Imported "${result.parentTitle}" with its detailed note.'
        : 'Imported "${result.parentTitle}" with '
            '${result.childTopicCount} child topics and '
            '${result.noteCount} notes.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  } on FormatException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid JSON file: ${error.message}')),
    );
  } on SingleTopicJsonImportException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('JSON import stopped: ${error.message}')),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Unable to import this JSON file. No changes were confirmed.'),
      ),
    );
  }
}

Future<void> _importPdfForTopic(
  BuildContext context,
  WidgetRef ref,
  String topicUuid,
) async {
  if (!kDebugMode) return;

  String? storedPath;

  try {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (!context.mounted || selection == null) return;

    final selectedFile = selection.files.single;
    final sourcePath = selectedFile.path;

    if (sourcePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to access the selected PDF.')),
      );
      return;
    }

    final defaultTitle = selectedFile.name.replaceFirst(
      RegExp(r'\.pdf$', caseSensitive: false),
      '',
    );
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _PdfTitleDialog(
        initialTitle: defaultTitle,
        heading: 'Import PDF',
      ),
    );

    if (!context.mounted || title == null || title.isEmpty) return;

    final storage = ref.read(learningResourceFileStorageProvider);
    final repository =
        await ref.read(learningResourceRepositoryProvider.future);

    final existingResources = await repository.getAll();
    if (!context.mounted) return;

    for (final resource in existingResources) {
      if (resource.fileSizeBytes != selectedFile.size) continue;

      if (await storage.hasSameContent(
        sourcePath,
        resource.relativeFilePath,
      )) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This PDF is already in your Library as "${resource.title}".',
            ),
          ),
        );
        return;
      }
    }

    storedPath = await storage.importPdf(sourcePath);
    final clock = ref.read(clockProvider);

    await repository.save(
      LearningResource(
        uuid: UuidGenerator().call(),
        topicUuid: topicUuid,
        title: title,
        originalFileName: selectedFile.name,
        relativeFilePath: storedPath,
        fileSizeBytes: selectedFile.size,
        importedAt: clock.now(),
      ),
    );

    if (!context.mounted) return;

    ref.invalidate(taxonomyBrowserProvider(topicUuid));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF imported successfully.')),
    );
  } catch (_) {
    if (storedPath != null) {
      try {
        await ref
            .read(learningResourceFileStorageProvider)
            .deletePdf(storedPath);
      } catch (_) {
        // Preserve the original import error if cleanup also fails.
      }
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to import this PDF.'),
      ),
    );
  }
}

Uint8List _packageLessonForImport(String extension, Uint8List bytes) {
  if (bytes.isEmpty) {
    throw const FormatException('The selected file is empty.');
  }

  if (extension == 'zip') {
    try {
      const PrototypeLessonArchiveReader().read(bytes);
    } on FormatException catch (error) {
      if (error.message !=
          'The ZIP must contain lesson.json or one lesson JSON under content/.') {
        rethrow;
      }
      const PrototypeHtmlLessonArchiveReader().read(bytes);
    }
    return bytes;
  }

  final archive = Archive();

  if (extension == 'html' || extension == 'htm') {
    archive.addFile(ArchiveFile('index.html', bytes.length, bytes));
  } else if (extension == 'json') {
    archive.addFile(ArchiveFile('lesson.json', bytes.length, bytes));
  } else {
    throw const FormatException(
      'Choose an HTML, JSON, or ZIP lesson package.',
    );
  }

  final packagedBytes = Uint8List.fromList(ZipEncoder().encode(archive));

  if (extension == 'html' || extension == 'htm') {
    const PrototypeHtmlLessonArchiveReader().read(packagedBytes);
  } else {
    const PrototypeLessonArchiveReader().read(packagedBytes);
  }

  return packagedBytes;
}

Future<void> _importHtmlLessonForTopic(
  BuildContext context,
  WidgetRef ref,
  String topicUuid,
) async {
  if (!kDebugMode) return;

  final messenger = ScaffoldMessenger.of(context);
  String? storedPath;

  try {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['html', 'htm', 'json', 'zip'],
      allowMultiple: false,
      withData: true,
    );

    if (!context.mounted || selection == null) return;

    final selectedFile = selection.files.single;
    final extension = selectedFile.extension?.toLowerCase();

    if (extension != 'html' &&
        extension != 'htm' &&
        extension != 'json' &&
        extension != 'zip') {
      throw const FormatException(
        'Choose an HTML, JSON, or ZIP lesson package.',
      );
    }

    Uint8List? sourceBytes = selectedFile.bytes;
    if (sourceBytes == null && selectedFile.path != null) {
      sourceBytes = await File(selectedFile.path!).readAsBytes();
    }

    if (sourceBytes == null || sourceBytes.isEmpty) {
      throw const FormatException(
        'Unable to read the selected lesson file.',
      );
    }

    final packageBytes = _packageLessonForImport(extension!, sourceBytes);

    if (!context.mounted) return;

    final defaultTitle = selectedFile.name.replaceFirst(
      RegExp(r'\.(html|htm|json|zip)$', caseSensitive: false),
      '',
    );

    final title = await showDialog<String>(
      context: context,
      builder: (_) => _PdfTitleDialog(
        initialTitle: defaultTitle,
        heading: 'Import lesson',
      ),
    );

    if (!context.mounted || title == null || title.trim().isEmpty) return;

    final storage = ref.read(learningResourceFileStorageProvider);
    final repository =
        await ref.read(learningResourceRepositoryProvider.future);

    final existingResources = await repository.getAll();
    for (final resource in existingResources) {
      if (resource.originalFileName == selectedFile.name &&
          resource.fileSizeBytes == packageBytes.length &&
          resource.format == LearningResourceFormat.htmlLesson) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'A lesson package named "${resource.title}" is already in your Library.',
            ),
          ),
        );
        return;
      }
    }

    storedPath = await storage.importHtmlLessonPackageBytes(packageBytes);
    final clock = ref.read(clockProvider);

    await repository.save(
      LearningResource(
        uuid: UuidGenerator().call(),
        topicUuid: topicUuid,
        title: title.trim(),
        originalFileName: selectedFile.name,
        relativeFilePath: storedPath,
        fileSizeBytes: packageBytes.length,
        importedAt: clock.now(),
      ),
    );

    if (!context.mounted) return;

    ref.invalidate(taxonomyBrowserProvider(topicUuid));
    messenger.showSnackBar(
      const SnackBar(content: Text('Lesson imported successfully.')),
    );
  } catch (error) {
    if (storedPath != null) {
      try {
        await ref
            .read(learningResourceFileStorageProvider)
            .deleteHtmlLessonPackage(storedPath);
      } catch (_) {
        // Preserve the original import error if cleanup also fails.
      }
    }

    if (!context.mounted) return;

    final message = error is FormatException
        ? error.message
        : 'Unable to import this lesson. Check that the file is a valid HTML, JSON, or ZIP lesson package.';

    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _TopicNameDialog extends StatefulWidget {
  const _TopicNameDialog({this.initialTitle});

  final String? initialTitle;

  @override
  State<_TopicNameDialog> createState() => _TopicNameDialogState();
}

class _TopicNameDialogState extends State<_TopicNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialTitle != null;
    return AlertDialog(
      title: Text(editing ? 'Edit topic' : 'Add topic'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Topic name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          final title = value.trim();
          if (title.isNotEmpty) Navigator.of(context).pop(title);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final title = _controller.text.trim();
            if (title.isNotEmpty) Navigator.of(context).pop(title);
          },
          child: Text(editing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

class _PdfTitleDialog extends StatefulWidget {
  const _PdfTitleDialog({
    required this.initialTitle,
    this.heading = 'Import PDF',
  });

  final String initialTitle;
  final String heading;

  @override
  State<_PdfTitleDialog> createState() => _PdfTitleDialogState();
}

class _PdfTitleDialogState extends State<_PdfTitleDialog> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _titleController.text.trim();
    if (value.isNotEmpty) {
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.heading),
      content: TextField(
        controller: _titleController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Resource title',
          hintText: 'Enter a title',
        ),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Import'),
        ),
      ],
    );
  }
}

/// Browses a taxonomy node and its direct children or available notes.
class TaxonomyBrowserScreen extends ConsumerWidget {
  const TaxonomyBrowserScreen({
    required this.nodeUuid,
    super.key,
  });

  final String nodeUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserAsync = ref.watch(taxonomyBrowserProvider(nodeUuid));

    return Scaffold(
      appBar: AppBar(
        title: browserAsync.maybeWhen(
          data: (data) => Text(data.node.title),
          orElse: () => const Text('Library'),
        ),
        actions: browserAsync.maybeWhen(
          data: (data) => kDebugMode &&
                  data.node.nodeType == NodeType.topic &&
                  data.node.isUserCreated
              ? [
                  IconButton(
                    tooltip: 'Delete topic',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteUserCreatedTopic(
                      context,
                      ref,
                      data.node,
                      closeCurrentScreen: true,
                    ),
                  ),
                ]
              : const <Widget>[],
          orElse: () => const <Widget>[],
        ),
      ),
      body: browserAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Unable to load this section',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Please try again later.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (data) => _TaxonomyBrowserContent(
          data: data,
          onImportPdf: () => _importPdfForTopic(context, ref, data.node.uuid),
          onImportHtmlLesson: () =>
              _importHtmlLessonForTopic(context, ref, data.node.uuid),
          onImportJson: () =>
              _importStructuredJsonForTopic(context, ref, data.node),
          onAddTopic: () => _addTopic(context, ref, data.node),
          onRenameTopic: (topic) => _renameTopic(context, ref, topic),
          onDeleteTopic: (topic) =>
              _deleteUserCreatedTopic(context, ref, topic),
        ),
      ),
    );
  }
}

class _TaxonomyBrowserContent extends StatelessWidget {
  const _TaxonomyBrowserContent({
    required this.data,
    required this.onImportPdf,
    required this.onImportHtmlLesson,
    required this.onImportJson,
    required this.onAddTopic,
    required this.onRenameTopic,
    required this.onDeleteTopic,
  });

  final TaxonomyBrowserData data;
  final VoidCallback onImportPdf;
  final VoidCallback onImportHtmlLesson;
  final VoidCallback onImportJson;
  final VoidCallback onAddTopic;
  final ValueChanged<TaxonomyNode> onRenameTopic;
  final ValueChanged<TaxonomyNode> onDeleteTopic;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _Breadcrumbs(nodes: data.breadcrumb),
        const SizedBox(height: AppSpacing.lg),
        Text(
          data.node.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (data.node.shortDescription != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.node.shortDescription!,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (kDebugMode && data.node.nodeType == NodeType.system) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onAddTopic,
              icon: const Icon(Icons.add),
              label: const Text('Add topic'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (kDebugMode && data.children.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onImportJson,
              icon: const Icon(Icons.data_object_outlined),
              label: const Text('Import JSON'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (data.children.isNotEmpty)
          _ChildTopicsSection(
            children: data.children,
            childNodesByParent: data.childNodesByParent,
            canEditTopics: data.node.nodeType == NodeType.system,
            onRenameTopic: onRenameTopic,
            onDeleteTopic: onDeleteTopic,
          ),
        if (data.children.isNotEmpty &&
            (data.notes.isNotEmpty || data.resources.isNotEmpty)) ...[
          const SizedBox(height: AppSpacing.lg),
          _TopicNotesSection(
            notes: data.notes,
            resources: data.resources,
          ),
        ],
        if (data.children.isEmpty) ...[
          if (kDebugMode) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: onImportPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Import PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: onImportHtmlLesson,
                  icon: const Icon(Icons.language_outlined),
                  label: const Text('Import lesson'),
                ),
                OutlinedButton.icon(
                  onPressed: onImportJson,
                  icon: const Icon(Icons.data_object_outlined),
                  label: const Text('Import JSON'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _TopicNotesSection(
            notes: data.notes,
            resources: data.resources,
          ),
        ],
      ],
    );
  }
}

class _ChildTopicsSection extends StatelessWidget {
  const _ChildTopicsSection({
    required this.children,
    required this.childNodesByParent,
    required this.canEditTopics,
    required this.onRenameTopic,
    required this.onDeleteTopic,
  });

  final List<TaxonomyNode> children;
  final Map<String, List<TaxonomyNode>> childNodesByParent;
  final bool canEditTopics;
  final ValueChanged<TaxonomyNode> onRenameTopic;
  final ValueChanged<TaxonomyNode> onDeleteTopic;

  void _openNode(BuildContext context, TaxonomyNode node) {
    FocusManager.instance.primaryFocus?.unfocus();
    TaxonomyBrowserRoute(nodeUuid: node.uuid).push(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contents',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...children.map((child) {
          final metadata = '${_nodeTypeLabel(child.nodeType)}'
              '${child.noteCount > 0 ? ' · ${child.noteCount} notes' : ''}';

          Widget buildSubtitle() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (child.shortDescription != null)
                  Text(child.shortDescription!),
                Text(
                  metadata,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                title: Text(child.title),
                subtitle: buildSubtitle(),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (kDebugMode &&
                        canEditTopics &&
                        child.nodeType == NodeType.topic)
                      IconButton(
                        tooltip: 'Edit topic name',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => onRenameTopic(child),
                      ),
                    if (kDebugMode &&
                        child.nodeType == NodeType.topic &&
                        child.isUserCreated)
                      IconButton(
                        tooltip: 'Delete topic',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDeleteTopic(child),
                      ),
                  ],
                ),
                onTap: () => _openNode(context, child),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TopicNotesSection extends StatelessWidget {
  const _TopicNotesSection({
    required this.notes,
    required this.resources,
  });

  final List<Note> notes;
  final List<LearningResource> resources;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty && resources.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No learning material yet',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This topic does not have any notes available yet.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notes.isNotEmpty) ...[
          Text(
            'Learning material',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _NoteModeCard(note: note),
            ),
          ),
        ],
        if (resources.isNotEmpty) ...[
          if (notes.isNotEmpty) const SizedBox(height: AppSpacing.lg),
          Text(
            'PDF resources',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...resources.map(
            (resource) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _LearningResourceCard(resource: resource),
            ),
          ),
        ],
      ],
    );
  }
}

class _LearningResourceCard extends ConsumerWidget {
  const _LearningResourceCard({required this.resource});

  final LearningResource resource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: const Icon(Icons.picture_as_pdf_outlined),
        title: Text(resource.title),
        subtitle: Text(resource.originalFileName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kDebugMode)
              IconButton(
                tooltip: 'Delete PDF',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, ref),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          LearningResourceReaderRoute(resourceUuid: resource.uuid)
              .push(context);
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!kDebugMode) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete PDF?'),
        content: Text(
          '"${resource.title}" will be permanently removed from your Library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final storage = ref.read(learningResourceFileStorageProvider);
      final repository =
          await ref.read(learningResourceRepositoryProvider.future);

      final preferences = await SharedPreferences.getInstance();
      await StarterContentLedger(preferences)
          .recordDeletionIfStarter(resource.uuid);

      if (resource.format == LearningResourceFormat.htmlLesson) {
        await storage.deleteHtmlLessonPackage(resource.relativeFilePath);
      } else {
        await storage.deletePdf(resource.relativeFilePath);
      }
      await repository.deleteByUuid(resource.uuid);
      ref.invalidate(taxonomyBrowserProvider(resource.topicUuid));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resource.format == LearningResourceFormat.htmlLesson
                ? 'HTML lesson deleted.'
                : 'PDF deleted.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resource.format == LearningResourceFormat.htmlLesson
                ? 'Unable to delete this HTML lesson.'
                : 'Unable to delete this PDF.',
          ),
        ),
      );
    }
  }
}

class _NoteModeCard extends ConsumerWidget {
  const _NoteModeCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeDetails = _modeDetails(note.mode);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: Icon(modeDetails.icon),
        title: Text(modeDetails.title),
        subtitle: Text(note.title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kDebugMode)
              IconButton(
                tooltip: 'Delete note',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, ref),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          NoteReaderRoute(noteUuid: note.uuid).push(context);
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!kDebugMode) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text(
          '"${note.title}" will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final service = await ref.read(libraryServiceProvider.future);
      await service.deleteNote(note.uuid);
      ref.invalidate(taxonomyBrowserProvider(note.topicUuid));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete this note.')),
      );
    }
  }

  ({String title, IconData icon}) _modeDetails(Mode mode) {
    return switch (mode) {
      Mode.detailedNotes => (
          title: 'Detailed Notes',
          icon: Icons.notes_outlined,
        ),
      Mode.visualLearning => (
          title: 'Visual Learning',
          icon: Icons.auto_awesome_outlined,
        ),
      Mode.quickReview => (
          title: 'Quick Review',
          icon: Icons.flash_on_outlined,
        ),
    };
  }
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({
    required this.nodes,
  });

  final List<TaxonomyNode> nodes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (var index = 0; index < nodes.length; index++) ...[
          if (index > 0)
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          if (index < nodes.length - 1)
            TextButton(
              onPressed: () => TaxonomyBrowserRoute(
                nodeUuid: nodes[index].uuid,
              ).go(context),
              child: Text(nodes[index].title),
            )
          else
            Text(
              nodes[index].title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ],
    );
  }
}

String _nodeTypeLabel(NodeType nodeType) {
  return switch (nodeType) {
    NodeType.subject => 'Subject',
    NodeType.system => 'System',
    NodeType.topic => 'Topic',
    NodeType.custom => 'Custom',
  };
}
