import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injector.dart';
import '../../domain/entities/taxonomy_node.dart';

part 'taxonomy_browser_provider.g.dart';

/// The data required to render a taxonomy browser screen.
class TaxonomyBrowserData {
  const TaxonomyBrowserData({
    required this.node,
    required this.breadcrumb,
    required this.children,
  });

  final TaxonomyNode node;
  final List<TaxonomyNode> breadcrumb;
  final List<TaxonomyNode> children;
}

/// Loads a taxonomy node together with its breadcrumb and direct children.
@riverpod
Future<TaxonomyBrowserData> taxonomyBrowser(
  TaxonomyBrowserRef ref,
  String nodeUuid,
) async {
  final taxonomyRepository =
      await ref.watch(taxonomyRepositoryProvider.future);
  final navigationService =
      await ref.watch(taxonomyNavigationServiceProvider.future);

  final node = await taxonomyRepository.getByUuid(nodeUuid);

  if (node == null) {
    throw StateError('No taxonomy node found for uuid "$nodeUuid".');
  }

  final breadcrumb = await navigationService.getBreadcrumbPath(nodeUuid);
  final children = await taxonomyRepository.getChildren(nodeUuid);

  children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  return TaxonomyBrowserData(
    node: node,
    breadcrumb: breadcrumb,
    children: children,
  );
}
