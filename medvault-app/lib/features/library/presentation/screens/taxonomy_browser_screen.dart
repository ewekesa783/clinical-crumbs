import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/spacing_tokens.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/taxonomy_node.dart';
import '../providers/taxonomy_browser_provider.dart';

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
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (data) => _TaxonomyBrowserContent(data: data),
      ),
    );
  }
}

class _TaxonomyBrowserContent extends StatelessWidget {
  const _TaxonomyBrowserContent({
    required this.data,
  });

  final TaxonomyBrowserData data;

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
        if (data.children.isNotEmpty)
          _ChildTopicsSection(children: data.children)
        else
          _TopicNotesSection(notes: data.notes),
      ],
    );
  }
}

class _ChildTopicsSection extends StatelessWidget {
  const _ChildTopicsSection({
    required this.children,
  });

  final List<TaxonomyNode> children;

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
        ...children.map(
          (child) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                title: Text(child.title),
                subtitle: child.shortDescription == null
                    ? null
                    : Text(child.shortDescription!),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => TaxonomyBrowserRoute(
                  nodeUuid: child.uuid,
                ).go(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicNotesSection extends StatelessWidget {
  const _TopicNotesSection({
    required this.notes,
  });

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
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
    );
  }
}

class _NoteModeCard extends StatelessWidget {
  const _NoteModeCard({
    required this.note,
  });

  final Note note;

  @override
  Widget build(BuildContext context) {
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
        trailing: const Icon(Icons.chevron_right),
        onTap: () => NoteReaderRoute(noteUuid: note.uuid).go(context),
      ),
    );
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
