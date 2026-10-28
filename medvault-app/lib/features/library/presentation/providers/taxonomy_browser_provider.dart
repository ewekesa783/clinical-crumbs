import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injector.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/learning_resource.dart';
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
    this.resources = const [],
    this.childResources = const {},
    this.childNodesByParent = const {},
  });

  final TaxonomyNode node;
  final List<TaxonomyNode> breadcrumb;
  final List<TaxonomyNode> children;
  final TopicNotes? topicNotes;
  final List<LearningResource> resources;
  final Map<String, List<LearningResource>> childResources;
  final Map<String, List<TaxonomyNode>> childNodesByParent;

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
  final taxonomyRepository = await ref.watch(taxonomyRepositoryProvider.future);
  final navigationService =
      await ref.watch(taxonomyNavigationServiceProvider.future);

  final node = await taxonomyRepository.getByUuid(nodeUuid);

  if (node == null) {
    throw StateError('No taxonomy node found for uuid "$nodeUuid".');
  }

  final breadcrumb = await navigationService.getBreadcrumbPath(nodeUuid);
  final children = await taxonomyRepository.getChildren(nodeUuid);

  children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final childNodesByParent = <String, List<TaxonomyNode>>{};
  for (final child in children) {
    final grandchildren = await taxonomyRepository.getChildren(child.uuid);
    grandchildren.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (grandchildren.isNotEmpty) {
      childNodesByParent[child.uuid] = grandchildren;
    }
  }

  TopicNotes? topicNotes;
  final childResources = <String, List<LearningResource>>{};
  final resources = await (await ref.watch(
    learningResourceRepositoryProvider.future,
  ))
      .getByTopicUuid(nodeUuid);

  final resourceRepository =
      await ref.watch(learningResourceRepositoryProvider.future);

  if (children.isEmpty) {
    final libraryService = await ref.watch(libraryServiceProvider.future);
    topicNotes = await libraryService.getTopicNotes(nodeUuid);
  } else {
    final childUuids = children.map((child) => child.uuid).toSet();
    final allResources = await resourceRepository.getAll();

    for (final resource in allResources) {
      if (childUuids.contains(resource.topicUuid)) {
        childResources.putIfAbsent(resource.topicUuid, () => []).add(resource);
      }
    }

    for (final topicResources in childResources.values) {
      topicResources.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
  }

  return TaxonomyBrowserData(
    node: node,
    breadcrumb: breadcrumb,
    children: children,
    topicNotes: topicNotes,
    resources: resources,
    childResources: childResources,
    childNodesByParent: childNodesByParent,
  );
}
