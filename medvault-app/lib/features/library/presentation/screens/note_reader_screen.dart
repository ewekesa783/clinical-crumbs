import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/spacing_tokens.dart';
import '../../domain/entities/citation.dart';
import '../../domain/services/dto/note_with_citations.dart';
import '../providers/note_bookmark_provider.dart';
import '../providers/note_reader_provider.dart';

/// Displays a single note and its resolved citations.
class NoteReaderScreen extends ConsumerWidget {
  const NoteReaderScreen({
    required this.noteUuid,
    super.key,
  });

  final String noteUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteReaderProvider(noteUuid));

    return Scaffold(
      appBar: AppBar(
        title: noteAsync.maybeWhen(
          data: (data) =>
              data == null ? const Text('Note') : Text(data.note.title),
          orElse: () => const Text('Note'),
        ),
        actions: [
          if (noteAsync.hasValue && noteAsync.value != null)
            _BookmarkButton(noteUuid: noteUuid),
        ],
      ),
      body: noteAsync.when(
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
                  'Unable to load this note',
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
        data: (data) {
          if (data == null) {
            return const Center(
              child: Text('Note not found'),
            );
          }

          return _NoteReaderContent(data: data);
        },
      ),
    );
  }
}

class _BookmarkButton extends ConsumerWidget {
  const _BookmarkButton({
    required this.noteUuid,
  });

  final String noteUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkAsync = ref.watch(noteBookmarkProvider(noteUuid));

    return IconButton(
      tooltip: bookmarkAsync.maybeWhen(
        data: (bookmarked) =>
            bookmarked ? 'Bookmarked' : 'Bookmark note',
        orElse: () => 'Bookmark note',
      ),
      onPressed: bookmarkAsync.maybeWhen(
        data: (bookmarked) {
          if (bookmarked) return null;

          return () {
            ref
                .read(noteBookmarkProvider(noteUuid).notifier)
                .bookmark();
          };
        },
        orElse: () => null,
      ),
      icon: bookmarkAsync.maybeWhen(
        loading: () => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        data: (bookmarked) => Icon(
          bookmarked ? Icons.bookmark : Icons.bookmark_border,
        ),
        orElse: () => const Icon(Icons.bookmark_border),
      ),
    );
  }
}

class _NoteReaderContent extends StatelessWidget {
  const _NoteReaderContent({
    required this.data,
  });

  final NoteWithCitations data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          data.note.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        MarkdownBody(
          data: data.note.bodyMarkdown,
          selectable: true,
        ),
        if (data.citations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'References',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CitationsList(citations: data.citations),
        ],
      ],
    );
  }
}

class _CitationsList extends StatelessWidget {
  const _CitationsList({
    required this.citations,
  });

  final List<Citation> citations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...citations.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _CitationTile(
              number: entry.key + 1,
              citation: entry.value,
            ),
          ),
        ),
      ],
    );
  }
}

class _CitationTile extends StatelessWidget {
  const _CitationTile({
    required this.number,
    required this.citation,
  });

  final int number;
  final Citation citation;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (citation.authors != null) citation.authors!,
      if (citation.publicationYear != null)
        citation.publicationYear.toString(),
      if (citation.pageReference != null) citation.pageReference!,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$number.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                citation.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  details.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (citation.url != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  citation.url!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
