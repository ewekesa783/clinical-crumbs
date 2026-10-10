import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  'Please try again later.',
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
        data: (bookmarked) => bookmarked ? 'Bookmarked' : 'Bookmark note',
        orElse: () => 'Bookmark note',
      ),
      onPressed: bookmarkAsync.maybeWhen(
        data: (bookmarked) {
          if (bookmarked) return null;

          return () {
            ref.read(noteBookmarkProvider(noteUuid).notifier).bookmark();
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

class _NoteReaderContent extends StatefulWidget {
  const _NoteReaderContent({
    required this.data,
  });

  final NoteWithCitations data;

  @override
  State<_NoteReaderContent> createState() => _NoteReaderContentState();
}

class _NoteReaderContentState extends State<_NoteReaderContent> {
  final Map<int, GlobalKey> _sectionKeys = {};
  String? _lastMarkdown;

  List<_NoteSection> _parseSections(String markdown) {
    final sections = <_NoteSection>[];
    final currentLines = <String>[];
    String? heading;
    var level = 0;
    var inFence = false;
    var fenceMarker = '';

    void flush() {
      if (currentLines.isEmpty && heading == null) return;
      sections.add(_NoteSection(
        heading: heading,
        level: level,
        markdown: currentLines.join('\n').trim(),
      ));
      currentLines.clear();
    }

    for (final line in markdown.split('\n')) {
      final fence = RegExp(r'^\s*(```+|~~~+)').firstMatch(line);
      if (fence != null) {
        final marker = fence.group(1)![0];
        if (!inFence) {
          inFence = true;
          fenceMarker = marker;
        } else if (marker == fenceMarker) {
          inFence = false;
        }
        currentLines.add(line);
        continue;
      }

      final match = inFence
          ? null
          : RegExp(r'^ {0,3}(#{1,6})\s+(.+?)\s*#*\s*$').firstMatch(line);

      if (match == null) {
        currentLines.add(line);
        continue;
      }

      flush();
      level = match.group(1)!.length;
      heading = match.group(2)!.trim();
    }

    flush();
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final markdown = data.note.bodyMarkdown;
    final sections = _parseSections(markdown);

    if (_lastMarkdown != markdown || _sectionKeys.length != sections.length) {
      _lastMarkdown = markdown;
      _sectionKeys
        ..clear()
        ..addEntries(
          List.generate(
            sections.length,
            (index) => MapEntry(index, GlobalKey()),
          ),
        );
    }

    final headings = sections
        .asMap()
        .entries
        .where((entry) => entry.value.heading != null)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.note.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (headings.isNotEmpty) ...[
            ExpansionTile(
              key: const ValueKey('note-outline'),
              tilePadding: EdgeInsets.zero,
              title: const Text('On this page'),
              children: headings.map((entry) {
                final section = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.only(
                    left: AppSpacing.md * section.level,
                    right: AppSpacing.sm,
                  ),
                  dense: true,
                  title: Text(section.heading!),
                  onTap: () {
                    final target = _sectionKeys[entry.key]?.currentContext;
                    if (target != null) {
                      Scrollable.ensureVisible(
                        target,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: 0.08,
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ...sections.asMap().entries.map((entry) {
            final section = entry.value;
            return Container(
              key: _sectionKeys[entry.key],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (section.heading != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: AppSpacing.sm,
                      ),
                      child: Text(
                        section.heading!,
                        style: _headingStyle(context, section.level),
                      ),
                    ),
                  if (section.markdown.isNotEmpty)
                    MarkdownBody(
                      data: section.markdown,
                      selectable: true,
                      onTapLink: (text, href, title) async {
                        if (href == null) return;
                        final uri = Uri.tryParse(href);
                        if (uri == null ||
                            (uri.scheme != 'http' && uri.scheme != 'https') ||
                            uri.host.isEmpty) {
                          return;
                        }
                        try {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {
                          // Keep the reader usable if the external app cannot open.
                        }
                      },
                    ),
                ],
              ),
            );
          }),
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
      ),
    );
  }

  TextStyle? _headingStyle(BuildContext context, int level) {
    final theme = Theme.of(context).textTheme;
    return switch (level) {
      1 => theme.headlineMedium,
      2 => theme.titleLarge,
      3 => theme.titleMedium,
      4 => theme.titleSmall,
      _ => theme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
    };
  }
}

class _NoteSection {
  const _NoteSection({
    required this.heading,
    required this.level,
    required this.markdown,
  });

  final String? heading;
  final int level;
  final String markdown;
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
      if (citation.publicationYear != null) citation.publicationYear.toString(),
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
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    final uri = Uri.tryParse(citation.url!);
                    if (uri == null ||
                        (uri.scheme != "http" && uri.scheme != "https") ||
                        uri.host.isEmpty) {
                      return;
                    }

                    try {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {
                      // Keep the reader usable if the external app cannot open.
                    }
                  },
                  child: Text(
                    citation.url!,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
