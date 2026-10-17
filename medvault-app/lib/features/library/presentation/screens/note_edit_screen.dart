import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/spacing_tokens.dart';
import '../../../../core/di/injector.dart';
import '../../../../features/home/presentation/providers/home_dashboard_provider.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/taxonomy_node.dart';
import '../providers/library_roots_provider.dart';
import '../providers/note_reader_provider.dart';
import '../providers/note_search_provider.dart';
import '../providers/taxonomy_browser_provider.dart';

/// Edits note metadata only. Authored body and citation content remain untouched.
class NoteEditScreen extends ConsumerStatefulWidget {
  const NoteEditScreen({
    required this.noteUuid,
    super.key,
  });

  final String noteUuid;

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();

  Note? _note;
  String? _topicUuid;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String value) {
    final tags = <String>[];
    final seen = <String>{};
    for (final raw in value.split(',')) {
      final tag = raw.trim();
      if (tag.isNotEmpty && seen.add(tag.toLowerCase())) {
        tags.add(tag);
      }
    }
    return tags;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final note = _note;
    final topicUuid = _topicUuid;
    if (note == null || topicUuid == null) return;

    setState(() => _saving = true);
    try {
      final service = await ref.read(libraryServiceProvider.future);
      await service.updateNoteMetadata(
        noteUuid: note.uuid,
        title: _titleController.text,
        tags: _parseTags(_tagsController.text),
        topicUuid: topicUuid,
      );

      ref.invalidate(noteReaderProvider(note.uuid));
      ref.invalidate(taxonomyBrowserProvider(note.topicUuid));
      ref.invalidate(taxonomyBrowserProvider(topicUuid));
      ref.invalidate(noteSearchProvider);
      ref.invalidate(allLibraryNotesProvider);
      ref.invalidate(libraryRootsProvider);
      ref.invalidate(libraryTaxonomyNodesProvider);
      ref.invalidate(homeDashboardProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note details updated')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = error is StateError || error is ArgumentError
          ? error
              .toString()
              .replaceFirst('Bad state: ', '')
              .replaceFirst('Invalid argument(s): ', '')
          : 'Unable to save note details. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteReaderProvider(widget.noteUuid));
    final taxonomyAsync = ref.watch(libraryTaxonomyNodesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit note details'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: Text('Unable to load this note.'),
        ),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Note not found.'));
          }

          final note = data.note;
          if (!_initialized || _note?.uuid != note.uuid) {
            _initialized = true;
            _note = note;
            _topicUuid = note.topicUuid;
            _titleController.text = note.title;
            _tagsController.text = note.tags.join(', ');
          }

          return taxonomyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const Center(
              child: Text('Unable to load library topics.'),
            ),
            data: (nodes) {
              final topics = nodes
                  .where((node) => node.nodeType == NodeType.topic)
                  .toList()
                ..sort((a, b) {
                  final pathComparison = a.path.compareTo(b.path);
                  return pathComparison != 0
                      ? pathComparison
                      : a.title.compareTo(b.title);
                });

              if (!topics.any((topic) => topic.uuid == _topicUuid)) {
                topics.insert(
                  0,
                  nodes.firstWhere(
                    (node) => node.uuid == note.topicUuid,
                    orElse: () => TaxonomyNode(
                      uuid: note.topicUuid,
                      path: note.topicUuid,
                      depth: 0,
                      nodeType: NodeType.topic,
                      title: 'Current topic',
                      slug: 'current-topic',
                      sortOrder: 0,
                      noteCount: 0,
                      isUserCreated: false,
                      createdAt: note.createdAt,
                      updatedAt: note.updatedAt,
                      sync: note.sync,
                    ),
                  ),
                );
              }

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      'Metadata only',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'The note body, learning mode, citations, and identity '
                      'will remain unchanged.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter a title.'
                              : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        hintText: 'Example: tag one, tag two',
                        helperText: 'Separate tags with commas.',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.none,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<String>(
                      value: _topicUuid,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        border: OutlineInputBorder(),
                      ),
                      items: topics.map((topic) {
                        return DropdownMenuItem<String>(
                          value: topic.uuid,
                          child: Text(
                            topic.path.replaceAll('/', ' / '),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _topicUuid = value),
                      validator: (value) =>
                          value == null ? 'Choose a topic.' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Learning mode'),
                      subtitle: Text(_modeLabel(note.mode)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _modeLabel(Mode mode) {
    switch (mode) {
      case Mode.detailedNotes:
        return 'Detailed notes';
      case Mode.visualLearning:
        return 'Visual learning';
      case Mode.quickReview:
        return 'Quick review';
    }
  }
}
