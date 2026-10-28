import '../../../../core/sync/sync_metadata_factory.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/taxonomy_node.dart';
import '../../domain/repositories/taxonomy_repository.dart';
import 'initial_taxonomy_subunits.dart';

/// Adds missing first-level subunits under the matching initial root units.
///
/// Existing records are never overwritten. Safe to invoke at startup.
class InitialTaxonomySubunitSeeder {
  const InitialTaxonomySubunitSeeder({
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
    final rootsBySlug = <String, TaxonomyNode>{
      for (final node in nodes)
        if (node.parentUuid == null) node.slug: node,
    };
    final siblingSlugs = <String>{
      for (final node in nodes)
        if (node.parentUuid != null) '${node.parentUuid}/${node.slug}',
    };

    for (final subunit in initialTaxonomySubunits) {
      final parent = rootsBySlug[subunit.parentSlug];
      if (parent == null) continue;
      if (existingUuids.contains(subunit.uuid)) continue;

      final siblingKey = '${parent.uuid}/${subunit.slug}';
      if (siblingSlugs.contains(siblingKey)) continue;

      final now = _clock.now();
      await _taxonomyRepository.save(
        TaxonomyNode(
          uuid: subunit.uuid,
          parentUuid: parent.uuid,
          path: '${parent.path}/${subunit.uuid}',
          depth: parent.depth + 1,
          nodeType: NodeType.system,
          title: subunit.title,
          slug: subunit.slug,
          sortOrder: subunit.sortOrder,
          noteCount: 0,
          isUserCreated: false,
          createdAt: now,
          updatedAt: now,
          sync: _syncMetadataFactory(),
        ),
      );

      existingUuids.add(subunit.uuid);
      siblingSlugs.add(siblingKey);
    }
  }
}
