import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:medvault_app/app/router/app_router.dart';
import 'package:medvault_app/core/constants/spacing_tokens.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';
import 'package:medvault_app/features/library/presentation/providers/library_roots_provider.dart';
import 'package:medvault_app/features/library/presentation/providers/note_search_provider.dart';

/// Library landing screen.
///
/// Displays taxonomy roots by default and supports searching notes by title,
/// body text, and tags.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';
  String _debouncedQuery = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search notes by title, text or tag',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _query.length < 2
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

  Widget _buildSearchResults(String query) {
    final resultsAsync = ref.watch(noteSearchProvider(query));

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
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      data: (notes) {
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

        final sortedNotes = [...notes]..sort((a, b) {
            final relevanceComparison =
                relevance(a, query).compareTo(relevance(b, query));

            if (relevanceComparison != 0) return relevanceComparison;

            return b.updatedAt.compareTo(a.updatedAt);
          });
        if (sortedNotes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'No notes found for "$query"',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: sortedNotes.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final note = sortedNotes[index];
            return _buildNoteResult(note);
          },
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
        onTap: () => NoteReaderRoute(noteUuid: note.uuid).go(context),
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
                error.toString(),
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
                onTap: () => TaxonomyBrowserRoute(
                  nodeUuid: node.uuid,
                ).go(context),
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
