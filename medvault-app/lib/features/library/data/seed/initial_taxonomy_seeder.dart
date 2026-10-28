import '../../../../core/sync/sync_metadata_factory.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/taxonomy_node.dart';
import '../../domain/repositories/taxonomy_repository.dart';
import 'initial_taxonomy_units.dart';

/// Adds any missing initial root units without modifying existing records.
///
/// Safe to invoke on every startup. Future units can be added to
/// [initialTaxonomyUnits] without changing the Library UI.
class InitialTaxonomySeeder {
  const InitialTaxonomySeeder({
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
    final existingNodes = await _taxonomyRepository.getAll();
    final existingUuids = existingNodes.map((node) => node.uuid).toSet();
    final existingRootSlugs = existingNodes
        .where((node) => node.parentUuid == null)
        .map((node) => node.slug)
        .toSet();

    for (final unit in initialTaxonomyUnits) {
      // Never replace a record already using this stable identifier.
      if (existingUuids.contains(unit.uuid)) continue;

      // Avoid colliding with a root created by an earlier import or test.
      if (existingRootSlugs.contains(unit.slug)) continue;

      final now = _clock.now();
      await _taxonomyRepository.save(
        TaxonomyNode(
          uuid: unit.uuid,
          parentUuid: null,
          path: unit.uuid,
          depth: 0,
          nodeType: NodeType.subject,
          title: unit.title,
          slug: unit.slug,
          sortOrder: unit.sortOrder,
          noteCount: 0,
          isUserCreated: false,
          createdAt: now,
          updatedAt: now,
          sync: _syncMetadataFactory(),
        ),
      );

      existingUuids.add(unit.uuid);
      existingRootSlugs.add(unit.slug);
    }
  }
}
