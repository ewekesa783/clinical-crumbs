import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/spacing_tokens.dart';
import '../../domain/entities/taxonomy_node.dart';
import '../providers/taxonomy_browser_provider.dart';

/// Browses a taxonomy node and its direct children.
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
        Text(
          'Contents',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (data.children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              'No subtopics yet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          ...data.children.map(
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
          Text(
            nodes[index].title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
