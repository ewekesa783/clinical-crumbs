import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:medvault_shared/medvault_shared.dart';

import 'package:medvault_app/app/router/app_router.dart';
import 'package:medvault_app/core/constants/spacing_tokens.dart';
import 'package:medvault_app/core/di/injector.dart';
import 'package:medvault_app/features/library/data/repositories/curriculum_pack_importer.dart';
import 'package:medvault_app/features/library/data/repositories/curriculum_pack_exporter.dart';
import 'package:medvault_app/features/library/data/repositories/full_library_backup_exporter.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';
import 'package:medvault_app/features/library/presentation/providers/library_roots_provider.dart';
import 'package:medvault_app/features/library/presentation/providers/note_search_provider.dart';
import 'package:medvault_app/features/library/presentation/screens/topic_package_preview_screen.dart';
import 'package:medvault_app/features/library/presentation/screens/prototype_topic_package_preview_screen.dart';

/// Library landing screen.
///
/// Displays taxonomy roots by default and supports searching notes by title,
/// body text, and tags.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, this.focusSearchRequest});

  final String? focusSearchRequest;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _handledFocusRequest;

  Timer? _searchDebounce;
  String _query = '';
  String _debouncedQuery = '';
  Mode? _selectedMode;
  String? _selectedTaxonomyUuid;
  bool _isImporting = false;
  bool _isExporting = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scheduleSearchFocus(widget.focusSearchRequest);
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusSearchRequest != oldWidget.focusSearchRequest) {
      _scheduleSearchFocus(widget.focusSearchRequest);
    }
  }

  void _scheduleSearchFocus(String? request) {
    if (request == null || request == _handledFocusRequest) return;
    _handledFocusRequest = request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _onSearchChanged(String value) {
    final query = value.trim();

    setState(() {
      _query = query;
    });

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _debouncedQuery = query;
      });
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();

    setState(() {
      _query = '';
      _debouncedQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          if (kDebugMode) ...[
            IconButton(
              tooltip: 'Preview topic package',
              onPressed: (_isImporting || _isExporting)
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TopicPackagePreviewScreen(),
                        ),
                      );
                    },
              icon: const Icon(Icons.preview_outlined),
            ),
            IconButton(
              tooltip: 'Preview prototype lesson',
              onPressed: (_isImporting || _isExporting)
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const PrototypeTopicPackagePreviewScreen(),
                        ),
                      );
                    },
              icon: const Icon(Icons.auto_stories_outlined),
            ),
            IconButton(
              tooltip: 'Export backup',
              onPressed: (_isImporting || _isExporting) ? null : _exportBackup,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined),
            ),
            IconButton(
              tooltip: 'Import curriculum pack',
              onPressed:
                  (_isImporting || _isExporting) ? null : _importCurriculumPack,
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_upload_outlined),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search sections, notes, PDFs, or tags',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_query.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      tooltip: _activeFilterCount == 0
                          ? 'Open filters'
                          : 'Open filters ($_activeFilterCount active)',
                      onPressed: _openFilters,
                      icon: Badge(
                        isLabelVisible: _activeFilterCount > 0,
                        label: Text('$_activeFilterCount'),
                        child: const Icon(Icons.tune),
                      ),
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
          Expanded(
            child: _query.length < 2 && !_hasActiveFilters
                ? _buildLibraryRoots()
                : _query != _debouncedQuery
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _buildSearchResults(_debouncedQuery),
          ),
        ],
      ),
    );
  }

  int get _activeFilterCount =>
      (_selectedMode == null ? 0 : 1) + (_selectedTaxonomyUuid == null ? 0 : 1);

  Future<void> _openFilters() async {
    List<TaxonomyNode> nodes;
    try {
      nodes = ref.read(libraryTaxonomyNodesProvider).valueOrNull ??
          await ref.read(libraryTaxonomyNodesProvider.future);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to load subject and topic filters.')),
      );
      return;
    }

    if (!mounted) return;

    Mode? draftMode = _selectedMode;
    String? draftTaxonomyUuid = _selectedTaxonomyUuid;
    final byUuid = {for (final node in nodes) node.uuid: node};

    String topicLabel(TaxonomyNode node) {
      final titles = node.path
          .split('/')
          .map((uuid) => byUuid[uuid]?.title)
          .whereType<String>()
          .toList();
      return titles.isEmpty ? node.title : titles.join(' / ');
    }

    final result = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Filter library',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DropdownButtonFormField<Mode?>(
                        value: draftMode,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Note mode',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<Mode?>(
                            value: null,
                            child: Text('All modes'),
                          ),
                          ...Mode.values.map(
                            (mode) => DropdownMenuItem<Mode?>(
                              value: mode,
                              child: Text(_modeLabel(mode)),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setSheetState(() => draftMode = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String?>(
                        value: draftTaxonomyUuid,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Subject / topic',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All subjects / topics'),
                          ),
                          ...nodes.map(
                            (node) => DropdownMenuItem<String?>(
                              value: node.uuid,
                              child: Text(
                                topicLabel(node),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setSheetState(
                            () => draftTaxonomyUuid = value,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                draftMode = null;
                                draftTaxonomyUuid = null;
                              });
                            },
                            child: const Text('Clear filters'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop({
                                'mode': draftMode,
                                'taxonomyUuid': draftTaxonomyUuid,
                              });
                            },
                            child: const Text('Apply filters'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    setState(() {
      _selectedMode = result['mode'] as Mode?;
      _selectedTaxonomyUuid = result['taxonomyUuid'] as String?;
    });
  }

  Future<void> _exportBackup() async {
    if (!kDebugMode) return;
    setState(() => _isExporting = true);

    try {
      final isar = await ref.read(appDatabaseProvider.future);
      final fileStorage = ref.read(learningResourceFileStorageProvider);
      final bytes = await FullLibraryBackupExporter(
        isar: isar,
        fileStorage: fileStorage,
      ).exportZip();

      if (!mounted) return;

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Clinical Crumbs full-library backup',
        fileName: 'clinical-crumbs-full-backup.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
        bytes: bytes,
      );

      if (!mounted || savedPath == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full-library backup exported successfully.'),
        ),
      );
    } on CurriculumPackExportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } on FullLibraryBackupExportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not export the backup. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<bool> _confirmCurriculumPackImport(CurriculumPack pack) async {
    final validation = const CurriculumPackValidator().validate(pack);

    if (!mounted) return false;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Preview curriculum pack'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pack.manifest.title,
                      style: Theme.of(dialogContext).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Pack version: ${pack.manifest.version}'),
                    Text(
                      'Format version: ${pack.manifest.formatVersion}',
                    ),
                    if (pack.manifest.description?.trim().isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 8),
                      Text(pack.manifest.description!),
                    ],
                    const Divider(height: 24),
                    Text('Taxonomy nodes: ${pack.taxonomyNodes.length}'),
                    Text('Notes: ${pack.notes.length}'),
                    Text('Citations: ${pack.citations.length}'),
                    const SizedBox(height: 16),
                    if (validation.isValid)
                      const Text(
                        'Structural validation passed. Existing-record '
                        'conflicts will be checked before any records are '
                        'written. Existing data will not be overwritten.',
                      )
                    else ...[
                      Text(
                        'Validation failed (${validation.issues.length} '
                        'issue${validation.issues.length == 1 ? '' : 's'}). '
                        'This pack cannot be imported.',
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...validation.issues.take(8).map(
                            (issue) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text('${issue.path}: ${issue.message}'),
                            ),
                          ),
                      if (validation.issues.length > 8)
                        Text(
                          'And ${validation.issues.length - 8} more issue(s).',
                        ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: validation.isValid
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                child: const Text('Import pack'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showCurriculumPackImportSummary(
    CurriculumPackImportResult result,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Taxonomy nodes imported: ${result.taxonomyNodesImported}'),
            Text('Notes imported: ${result.notesImported}'),
            Text('Citations imported: ${result.citationsImported}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _importCurriculumPack() async {
    if (!kDebugMode) return;
    setState(() => _isImporting = true);

    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (!mounted || selection == null) return;

      final bytes = selection.files.single.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException(
          'The selected file could not be read or is empty.',
        );
      }

      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        throw const FormatException(
          'The JSON root must be an object containing a curriculum pack.',
        );
      }

      final pack = CurriculumPack.fromJson(
        Map<String, dynamic>.from(decoded),
      );

      final shouldImport = await _confirmCurriculumPackImport(pack);
      if (!shouldImport || !mounted) return;

      final isar = await ref.read(appDatabaseProvider.future);
      final metadataFactory =
          await ref.read(syncMetadataFactoryProvider.future);
      final clock = ref.read(clockProvider);

      final result = await CurriculumPackImporter(
        isar: isar,
        createSyncMetadata: metadataFactory.call,
        now: clock.now,
      ).importPack(pack);

      if (!mounted) return;

      ref.invalidate(libraryRootsProvider);
      ref.invalidate(noteSearchProvider);
      ref.invalidate(allLibraryNotesProvider);
      ref.invalidate(libraryTaxonomyNodesProvider);

      await _showCurriculumPackImportSummary(result);
    } on CurriculumPackImportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid curriculum pack: ${error.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not import this file. Check that it is a valid '
            'curriculum-pack JSON file.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  bool get _hasActiveFilters =>
      _selectedMode != null || _selectedTaxonomyUuid != null;

  Widget _buildSearchResults(String query) {
    final resultsAsync = ref.watch(librarySearchProvider(query));

    return resultsAsync.when(
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
                'Unable to search notes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Please try again later.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      data: (results) {
        final taxonomyNodes =
            ref.watch(libraryTaxonomyNodesProvider).valueOrNull ??
                <TaxonomyNode>[];
        final selectedNode = _selectedTaxonomyUuid == null
            ? null
            : taxonomyNodes
                .where((node) => node.uuid == _selectedTaxonomyUuid)
                .firstOrNull;

        final includedTopicUuids = selectedNode == null
            ? null
            : taxonomyNodes
                .where(
                  (node) =>
                      node.uuid == selectedNode.uuid ||
                      node.path.startsWith('${selectedNode.path}/'),
                )
                .map((node) => node.uuid)
                .toSet();

        final filteredNotes = results.notes.where((note) {
          if (_selectedMode != null && note.mode != _selectedMode) {
            return false;
          }
          if (includedTopicUuids != null &&
              !includedTopicUuids.contains(note.topicUuid)) {
            return false;
          }
          return true;
        }).toList();

        final filteredResources = results.resources.where((resource) {
          if (includedTopicUuids != null &&
              !includedTopicUuids.contains(resource.topicUuid)) {
            return false;
          }
          return true;
        }).toList();

        int relevance(Note note, String term) {
          final normalizedTerm = term.toLowerCase();

          if (note.title.toLowerCase().contains(normalizedTerm)) return 0;

          if (note.tags.any(
            (tag) => tag.toLowerCase().contains(normalizedTerm),
          )) {
            return 1;
          }

          final extract = note.plainTextExtract?.trim();
          if (extract != null &&
              extract.isNotEmpty &&
              extract.toLowerCase().contains(normalizedTerm)) {
            return 2;
          }

          if (note.bodyMarkdown.toLowerCase().contains(normalizedTerm)) {
            return 3;
          }

          return 4;
        }

        final sortedNotes = [...filteredNotes]..sort((a, b) {
            if (query.length >= 2) {
              final relevanceComparison =
                  relevance(a, query).compareTo(relevance(b, query));
              if (relevanceComparison != 0) return relevanceComparison;
            }
            return b.updatedAt.compareTo(a.updatedAt);
          });

        final sortedResources = [...filteredResources]..sort((a, b) {
            if (query.length >= 2) {
              final term = query.toLowerCase();
              final aTitleMatch = a.title.toLowerCase().contains(term);
              final bTitleMatch = b.title.toLowerCase().contains(term);
              if (aTitleMatch != bTitleMatch) {
                return aTitleMatch ? -1 : 1;
              }
            }
            return b.importedAt.compareTo(a.importedAt);
          });

        final filteredTaxonomyNodes = results.taxonomyNodes
            .where((node) =>
                includedTopicUuids == null ||
                includedTopicUuids.contains(node.uuid))
            .toList();
        filteredTaxonomyNodes.sort((a, b) {
          final aExact = a.title.toLowerCase() == query.trim().toLowerCase();
          final bExact = b.title.toLowerCase() == query.trim().toLowerCase();
          if (aExact != bExact) return aExact ? -1 : 1;
          final aStarts =
              a.title.toLowerCase().startsWith(query.trim().toLowerCase());
          final bStarts =
              b.title.toLowerCase().startsWith(query.trim().toLowerCase());
          if (aStarts != bStarts) return aStarts ? -1 : 1;
          final depthComparison = a.depth.compareTo(b.depth);
          if (depthComparison != 0) return depthComparison;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });

        final totalResults = filteredTaxonomyNodes.length +
            sortedNotes.length +
            sortedResources.length;
        if (totalResults == 0) {
          final message = query.length >= 2
              ? _hasActiveFilters
                  ? 'No library results found for "$query" with the selected filters.'
                  : 'No library results found for "$query"'
              : 'No library content matches the selected filters.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                0,
              ),
              child: Text(
                filteredTaxonomyNodes.isEmpty && sortedResources.isEmpty
                    ? '${sortedNotes.length} ${sortedNotes.length == 1 ? 'note' : 'notes'} found'
                    : '$totalResults ${totalResults == 1 ? 'result' : 'results'} found',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: totalResults,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index < filteredTaxonomyNodes.length) {
                    return _buildTaxonomyResult(
                      filteredTaxonomyNodes[index],
                      taxonomyNodes,
                    );
                  }

                  final noteIndex = index - filteredTaxonomyNodes.length;
                  if (noteIndex < sortedNotes.length) {
                    return _buildNoteResult(sortedNotes[noteIndex],
                        query: query);
                  }

                  final resourceIndex = noteIndex - sortedNotes.length;
                  final resource = sortedResources[resourceIndex];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(resource.title),
                      subtitle: Text(
                        resource.originalFileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        LearningResourceReaderRoute(
                          resourceUuid: resource.uuid,
                        ).push(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaxonomyResult(
    TaxonomyNode node,
    List<TaxonomyNode> allNodes,
  ) {
    final parent = node.parentUuid == null
        ? null
        : allNodes
            .where((candidate) => candidate.uuid == node.parentUuid)
            .firstOrNull;

    final subtitle = parent == null
        ? _nodeTypeLabel(node.nodeType)
        : '${_nodeTypeLabel(node.nodeType)} · ${parent.title}';

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: Icon(
          switch (node.nodeType) {
            NodeType.subject => Icons.menu_book_outlined,
            NodeType.system => Icons.account_tree_outlined,
            NodeType.topic => Icons.topic_outlined,
            NodeType.custom => Icons.folder_outlined,
          },
        ),
        title: Text(node.title),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          TaxonomyBrowserRoute(nodeUuid: node.uuid).push(context);
        },
      ),
    );
  }

  Widget _buildNoteResult(Note note, {String query = ''}) {
    final extract = note.plainTextExtract?.trim();
    final body = note.bodyMarkdown.trim();
    final normalizedQuery = query.trim();
    final queryLower = normalizedQuery.toLowerCase();

    // Prefer whichever text source actually contains the search term.
    // Title/tag matches fall back to the note's ordinary opening excerpt.
    final extractMatches = extract != null &&
        extract.isNotEmpty &&
        queryLower.isNotEmpty &&
        extract.toLowerCase().contains(queryLower);
    final bodyMatches =
        queryLower.isNotEmpty && body.toLowerCase().contains(queryLower);

    final excerptSource = extractMatches
        ? extract
        : bodyMatches
            ? body
            : extract != null && extract.isNotEmpty
                ? extract
                : body;

    final cleanedExcerpt = excerptSource
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAll(RegExp(r'~~~[\s\S]*?~~~'), ' ')
        .replaceAll(RegExp(r'[`*_>#\[\]]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final excerpt = _excerptAroundMatch(cleanedExcerpt, normalizedQuery);

    final subtitleParts = <String>[
      _modeLabel(note.mode),
      if (note.tags.isNotEmpty) note.tags.join(' · '),
      if (excerpt.isNotEmpty) excerpt,
    ];

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        title: Text(note.title),
        subtitle: Text(
          subtitleParts.join('\n'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: subtitleParts.length > 1,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          NoteReaderRoute(noteUuid: note.uuid).push(context);
        },
      ),
    );
  }

  String _excerptAroundMatch(String text, String query) {
    const contextBefore = 24;
    const contextAfter = 70;
    const maxLength = 180;

    if (text.length <= maxLength) return text;

    final term = query.trim();
    final matchIndex =
        term.isEmpty ? -1 : text.toLowerCase().indexOf(term.toLowerCase());

    if (matchIndex < 0) {
      final cutoff = text.lastIndexOf(' ', maxLength);
      final end = cutoff > 0 ? cutoff : maxLength;
      return '${text.substring(0, end).trimRight()}…';
    }

    var start = (matchIndex - contextBefore).clamp(0, text.length).toInt();
    var end =
        (matchIndex + term.length + contextAfter).clamp(0, text.length).toInt();

    if (start > 0) {
      final nextSpace = text.indexOf(' ', start);
      if (nextSpace >= 0 && nextSpace < matchIndex) {
        start = nextSpace + 1;
      }
    }

    if (end < text.length) {
      final nextSpace = text.indexOf(' ', end);
      if (nextSpace >= 0) end = nextSpace;
    }

    final excerpt = text.substring(start, end).trim();
    return '${start > 0 ? '…' : ''}$excerpt${end < text.length ? '…' : ''}';
  }

  Widget _buildLibraryRoots() {
    final rootsAsync = ref.watch(libraryRootsProvider);

    return rootsAsync.when(
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
                'Unable to load the library',
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
      data: (roots) {
        if (roots.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'No library content yet',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: roots.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final node = roots[index];

            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                title: Text(
                  node.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (node.shortDescription != null) ...[
                      Text(node.shortDescription!),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Text(
                      '${_nodeTypeLabel(node.nodeType)}'
                      '${node.noteCount > 0 ? ' · ${node.noteCount} notes' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  TaxonomyBrowserRoute(
                    nodeUuid: node.uuid,
                  ).push(context);
                },
              ),
            );
          },
        );
      },
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

String _modeLabel(Mode mode) {
  return switch (mode) {
    Mode.detailedNotes => 'Detailed notes',
    Mode.visualLearning => 'Visual learning',
    Mode.quickReview => 'Quick review',
  };
}
