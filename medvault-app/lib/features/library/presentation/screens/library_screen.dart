import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:medvault_shared/medvault_shared.dart';

import 'package:medvault_app/app/router/app_router.dart';
import 'package:medvault_app/core/constants/spacing_tokens.dart';
import 'package:medvault_app/core/di/injector.dart';
import 'package:medvault_app/features/library/data/repositories/curriculum_pack_importer.dart';
import 'package:medvault_app/features/library/data/repositories/curriculum_pack_exporter.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';
import 'package:medvault_app/features/library/presentation/providers/library_roots_provider.dart';
import 'package:medvault_app/features/library/presentation/providers/note_search_provider.dart';

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
                hintText: 'Search notes by title, text or tag',
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
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
    setState(() => _isExporting = true);

    try {
      final isar = await ref.read(appDatabaseProvider.future);
      final pack = await CurriculumPackExporter(isar: isar).exportPack();
      final json = const JsonEncoder.withIndent('  ').convert(pack.toJson());
      final bytes = Uint8List.fromList(utf8.encode(json));

      if (!mounted) return;

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export MedVault backup',
        fileName: 'medvault-backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (!mounted || savedPath == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup exported successfully.')),
      );
    } on CurriculumPackExportException catch (error) {
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

  Future<void> _importCurriculumPack() async {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${result.taxonomyNodesImported} topics, '
            '${result.notesImported} notes and '
            '${result.citationsImported} citations.',
          ),
        ),
      );
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
    final resultsAsync = query.length >= 2
        ? ref.watch(noteSearchProvider(query))
        : ref.watch(allLibraryNotesProvider);

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
      data: (notes) {
        final taxonomyNodes =
            ref.watch(libraryTaxonomyNodesProvider).valueOrNull ??
                <TaxonomyNode>[];
        final selectedNode = _selectedTaxonomyUuid == null
            ? null
            : taxonomyNodes
                .where(
                  (node) => node.uuid == _selectedTaxonomyUuid,
                )
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

        final filteredNotes = notes.where((note) {
          if (_selectedMode != null && note.mode != _selectedMode) {
            return false;
          }
          if (includedTopicUuids != null &&
              !includedTopicUuids.contains(note.topicUuid)) {
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
        if (sortedNotes.isEmpty) {
          final message = query.length >= 2
              ? _hasActiveFilters
                  ? 'No notes found for "$query" with the selected filters.'
                  : 'No notes found for "$query"'
              : 'No notes match the selected filters.';
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
                '${sortedNotes.length} '
                '${sortedNotes.length == 1 ? 'note' : 'notes'} found',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: sortedNotes.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final note = sortedNotes[index];
                  return _buildNoteResult(note);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoteResult(Note note) {
    final extract = note.plainTextExtract?.trim();
    final excerptSource =
        extract != null && extract.isNotEmpty ? extract : note.bodyMarkdown;
    final excerpt = excerptSource
        .replaceAll(RegExp(r'[`*_>#\[\]]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
                title: Text(node.title),
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
