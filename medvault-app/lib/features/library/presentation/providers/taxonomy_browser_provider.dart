import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injector.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/taxonomy_node.dart';
import '../../domain/services/dto/topic_notes.dart';

part 'taxonomy_browser_provider.g.dart';

/// The data required to render a taxonomy node and its contents.
class TaxonomyBrowserData {
  const TaxonomyBrowserData({
    required this.node,
    required this.breadcrumb,
    required this.children,
    required this.topicNotes,
  });

  final TaxonomyNode node;
  final List<TaxonomyNode> breadcrumb;
  final List<TaxonomyNode> children;
  final TopicNotes? topicNotes;

  /// Notes available for this topic, if it is a leaf node.
  List<Note> get notes => topicNotes?.notes ?? const [];
}

/// Loads a taxonomy node together with its breadcrumb, direct children,
/// and, for leaf nodes, the notes available for that topic.
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

  TopicNotes? topicNotes;

  if (children.isEmpty) {
    final libraryService = await ref.watch(libraryServiceProvider.future);
    topicNotes = await libraryService.getTopicNotes(nodeUuid);
  }

  return TaxonomyBrowserData(
    node: node,
    breadcrumb: breadcrumb,
    children: children,
    topicNotes: topicNotes,
  );
}
