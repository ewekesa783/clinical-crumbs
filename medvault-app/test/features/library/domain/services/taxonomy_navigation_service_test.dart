import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';
import 'package:medvault_app/features/library/domain/repositories/taxonomy_repository.dart';
import 'package:medvault_app/features/library/domain/services/taxonomy_navigation_service.dart';

class _FakeTaxonomyRepository implements TaxonomyRepository {
  final Map<String, TaxonomyNode> _store = {};

  @override
  Future<void> save(TaxonomyNode node) async => _store[node.uuid] = node;

  @override
  Future<TaxonomyNode?> getByUuid(String uuid) async => _store[uuid];

  @override
  Future<List<TaxonomyNode>> getChildren(String parentUuid) async =>
      _store.values.where((n) => n.parentUuid == parentUuid).toList();
}

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'device-1',
      syncRevision: 1,
    );

TaxonomyNode _node(String uuid, String? parentUuid) => TaxonomyNode(
      uuid: uuid,
      parentUuid: parentUuid,
      path: uuid,
      depth: parentUuid == null ? 0 : 1,
      nodeType: NodeType.topic,
      title: uuid,
      slug: uuid,
      sortOrder: 0,
      noteCount: 0,
      isUserCreated: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );

void main() {
  test('getBreadcrumbPath walks from root to the target node', () async {
    final repository = _FakeTaxonomyRepository();
    await repository.save(_node('root', null));
    await repository.save(_node('child', 'root'));
    await repository.save(_node('grandchild', 'child'));

    final service = TaxonomyNavigationService(taxonomyRepository: repository);
    final path = await service.getBreadcrumbPath('grandchild');

    expect(path.map((n) => n.uuid).toList(), ['root', 'child', 'grandchild']);
  });

  test('getBreadcrumbPath throws when the target node is missing', () async {
    final repository = _FakeTaxonomyRepository();
    final service = TaxonomyNavigationService(taxonomyRepository: repository);

    await expectLater(
      service.getBreadcrumbPath('missing-target'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'No taxonomy node found for uuid "missing-target".',
        ),
      ),
    );
  });

  test('getBreadcrumbPath throws when an ancestor is missing', () async {
    final repository = _FakeTaxonomyRepository();
    await repository.save(_node('child', 'missing-parent'));
    final service = TaxonomyNavigationService(taxonomyRepository: repository);

    await expectLater(
      service.getBreadcrumbPath('child'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'No taxonomy node found for uuid "missing-parent".',
        ),
      ),
    );
  });

  // No test for getSiblings(): that method does not exist on this
  // service (removed in Task A.2A). Sibling lookup, if ever needed, is
  // performed via TaxonomyRepository.getChildren(node.parentUuid)
  // directly by the caller.
}
