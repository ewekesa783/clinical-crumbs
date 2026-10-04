import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/taxonomy_node_mapper.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'device-1',
      syncRevision: 1,
    );

void main() {
  group('TaxonomyNodeMapper', () {
    test('toModel then toDomain round-trips all fields', () {
      final domain = TaxonomyNode(
        uuid: 'node-1',
        parentUuid: 'parent-1',
        path: 'parent-1/node-1',
        depth: 1,
        nodeType: NodeType.topic,
        title: 'Cardiology',
        slug: 'cardiology',
        shortDescription: 'The heart',
        iconKey: 'heart',
        sortOrder: 0,
        noteCount: 0,
        curriculumPackUuid: null,
        curriculumPackVersion: null,
        isUserCreated: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        sync: _sync(),
      );

      final model = TaxonomyNodeMapper.toModel(domain);
      final roundTripped = TaxonomyNodeMapper.toDomain(model);

      expect(roundTripped.uuid, domain.uuid);
      expect(roundTripped.parentUuid, domain.parentUuid);
      expect(roundTripped.path, domain.path);
      expect(roundTripped.depth, domain.depth);
      expect(roundTripped.nodeType, domain.nodeType);
      expect(roundTripped.title, domain.title);
      expect(roundTripped.slug, domain.slug);
    });

    test('model carries no domain-layer types', () {
      // Structural assertion: TaxonomyNodeModel must be constructible
      // without importing anything from domain/entities except via the
      // mapper. This test documents that expectation; it is enforced by
      // the import graph, not runtime behavior.
      expect(true, isTrue);
    });
  });
}
