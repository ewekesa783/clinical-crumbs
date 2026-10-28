import '../../../../core/sync/sync_metadata_factory.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/taxonomy_node.dart';
import '../../domain/repositories/taxonomy_repository.dart';
import 'initial_taxonomy_topics.dart';

/// Adds missing third-level topics beneath their existing specialties.
///
/// Existing records are never overwritten. Safe to invoke at startup.
class InitialTaxonomyTopicSeeder {
  const InitialTaxonomyTopicSeeder({
    required TaxonomyRepository taxonomyRepository,
    required SyncMetadataFactory syncMetadataFactory,
    required Clock clock,
  })  : _taxonomyRepository = taxonomyRepository,
        _syncMetadataFactory = syncMetadataFactory,
        _clock = clock;

  final TaxonomyRepository _taxonomyRepository;
  final SyncMetadataFactory _syncMetadataFactory;
  final Clock _clock;

  Future<void> seed() async {
    final nodes = await _taxonomyRepository.getAll();
    final existingUuids = nodes.map((node) => node.uuid).toSet();

    final specialtiesByUuid = <String, TaxonomyNode>{
      for (final node in nodes)
        if (node.nodeType == NodeType.system) node.uuid: node,
    };

    final siblingSlugs = <String>{
      for (final node in nodes)
        if (node.parentUuid != null) '${node.parentUuid}/${node.slug}',
    };

    for (final topic in initialTaxonomyTopics) {
      final parent = specialtiesByUuid[topic.parentUuid];
      if (parent == null) continue;
      if (existingUuids.contains(topic.uuid)) continue;

      final siblingKey = '${parent.uuid}/${topic.slug}';
      if (siblingSlugs.contains(siblingKey)) continue;

      final now = _clock.now();
      await _taxonomyRepository.save(
        TaxonomyNode(
          uuid: topic.uuid,
          parentUuid: parent.uuid,
          path: '${parent.path}/${topic.uuid}',
          depth: parent.depth + 1,
          nodeType: NodeType.topic,
          title: topic.title,
          slug: topic.slug,
          sortOrder: topic.sortOrder,
          noteCount: 0,
          isUserCreated: false,
          createdAt: now,
          updatedAt: now,
          sync: _syncMetadataFactory(),
        ),
      );

      existingUuids.add(topic.uuid);
      siblingSlugs.add(siblingKey);
    }
  }
}
