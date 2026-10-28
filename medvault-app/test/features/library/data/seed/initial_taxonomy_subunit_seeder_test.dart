import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/storage/device_identity.dart';
import 'package:medvault_app/core/sync/sync_metadata_factory.dart';
import 'package:medvault_app/core/time/clock.dart';
import 'package:medvault_app/features/library/data/seed/initial_taxonomy_seeder.dart';
import 'package:medvault_app/features/library/data/seed/initial_taxonomy_subunit_seeder.dart';
import 'package:medvault_app/features/library/data/seed/initial_taxonomy_subunits.dart';
import 'package:medvault_app/features/library/data/seed/initial_taxonomy_units.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';
import 'package:medvault_app/features/library/domain/repositories/taxonomy_repository.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 10, 19);
}

class _FakeTaxonomyRepository implements TaxonomyRepository {
  final Map<String, TaxonomyNode> nodes = {};
  int saveCount = 0;

  @override
  @override
  Future<void> deleteByUuid(String uuid) async => nodes.remove(uuid);

  Future<void> save(TaxonomyNode node) async {
    saveCount++;
    nodes[node.uuid] = node;
  }

  @override
  Future<TaxonomyNode?> getByUuid(String uuid) async => nodes[uuid];

  @override
  Future<List<TaxonomyNode>> getChildren(String parentUuid) async =>
      nodes.values.where((node) => node.parentUuid == parentUuid).toList();

  @override
  Future<List<TaxonomyNode>> getAll() async => nodes.values.toList();
}

void main() {
  late _FakeTaxonomyRepository repository;
  late _FixedClock clock;
  late SyncMetadataFactory syncMetadataFactory;
  late InitialTaxonomySeeder rootSeeder;
  late InitialTaxonomySubunitSeeder subunitSeeder;

  setUp(() {
    repository = _FakeTaxonomyRepository();
    clock = _FixedClock();
    syncMetadataFactory = SyncMetadataFactory(
      deviceIdentity: DeviceIdentity(deviceId: 'test-device'),
      clock: clock,
    );

    rootSeeder = InitialTaxonomySeeder(
      taxonomyRepository: repository,
      syncMetadataFactory: syncMetadataFactory,
      clock: clock,
    );

    subunitSeeder = InitialTaxonomySubunitSeeder(
      taxonomyRepository: repository,
      syncMetadataFactory: syncMetadataFactory,
      clock: clock,
    );
  });

  Future<void> seedHierarchy() async {
    await rootSeeder.seed();
    await subunitSeeder.seed();
  }

  TaxonomyNode makeExistingNode({
    required String uuid,
    required String parentUuid,
    required String path,
    required int depth,
    required String title,
    required String slug,
    int sortOrder = 0,
  }) {
    final now = DateTime.utc(2026, 1, 1);
    return TaxonomyNode(
      uuid: uuid,
      parentUuid: parentUuid,
      path: path,
      depth: depth,
      nodeType: NodeType.system,
      title: title,
      slug: slug,
      sortOrder: sortOrder,
      noteCount: 0,
      isUserCreated: false,
      createdAt: now,
      updatedAt: now,
      sync: syncMetadataFactory(),
    );
  }

  test('seeds every defined subunit beneath its matching root', () async {
    await seedHierarchy();

    expect(
      repository.nodes,
      hasLength(initialTaxonomyUnits.length + initialTaxonomySubunits.length),
    );

    for (final definition in initialTaxonomySubunits) {
      final root = initialTaxonomyUnits
          .singleWhere((unit) => unit.slug == definition.parentSlug);
      final rootNode = repository.nodes[root.uuid]!;
      final node = repository.nodes[definition.uuid];

      expect(node, isNotNull, reason: definition.title);
      expect(node!.parentUuid, root.uuid, reason: definition.title);
      expect(node.path, '${rootNode.path}/${definition.uuid}');
      expect(node.depth, rootNode.depth + 1);
      expect(node.nodeType, NodeType.system);
      expect(node.title, definition.title);
      expect(node.slug, definition.slug);
      expect(node.noteCount, 0);
      expect(node.isUserCreated, isFalse);
    }
  });

  test('seeds the configured Dental specialties', () async {
    await seedHierarchy();

    final dental = initialTaxonomyUnits.singleWhere(
      (unit) => unit.slug == 'dental',
    );
    final definitions = initialTaxonomySubunits
        .where((unit) => unit.parentSlug == 'dental')
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final children = repository.nodes.values
        .where((node) => node.parentUuid == dental.uuid)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    expect(repository.nodes[dental.uuid], isNotNull);
    expect(definitions, hasLength(6));
    expect(
      children.map((node) => node.title).toList(),
      definitions.map((definition) => definition.title).toList(),
    );
  });

  test('orders siblings according to their configured sort order', () async {
    await seedHierarchy();

    for (final root in initialTaxonomyUnits) {
      final expected = initialTaxonomySubunits
          .where((unit) => unit.parentSlug == root.slug)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final actual = (await repository.getChildren(root.uuid))
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      expect(
        actual.map((node) => node.title).toList(),
        expected.map((unit) => unit.title).toList(),
        reason: root.title,
      );
    }
  });

  test('repeated seeding does not create or save duplicate records', () async {
    await seedHierarchy();
    final savedCount = repository.saveCount;
    final nodeCount = repository.nodes.length;

    await subunitSeeder.seed();

    expect(repository.nodes, hasLength(nodeCount));
    expect(repository.saveCount, savedCount);
  });

  test('preserves an existing subunit with the same UUID', () async {
    await rootSeeder.seed();

    final definition = initialTaxonomySubunits.first;
    final root = initialTaxonomyUnits
        .singleWhere((unit) => unit.slug == definition.parentSlug);
    final rootNode = repository.nodes[root.uuid]!;

    await repository.save(
      makeExistingNode(
        uuid: definition.uuid,
        parentUuid: root.uuid,
        path: '${rootNode.path}/${definition.uuid}',
        depth: rootNode.depth + 1,
        title: 'My Existing Subunit',
        slug: definition.slug,
      ),
    );

    await subunitSeeder.seed();

    expect(repository.nodes[definition.uuid]!.title, 'My Existing Subunit');
    expect(
      repository.nodes,
      hasLength(initialTaxonomyUnits.length + initialTaxonomySubunits.length),
    );
  });

  test('does not create a duplicate sibling slug', () async {
    await rootSeeder.seed();

    final definition = initialTaxonomySubunits.first;
    final root = initialTaxonomyUnits
        .singleWhere((unit) => unit.slug == definition.parentSlug);
    final rootNode = repository.nodes[root.uuid]!;

    await repository.save(
      makeExistingNode(
        uuid: 'existing-custom-subunit',
        parentUuid: root.uuid,
        path: '${rootNode.path}/existing-custom-subunit',
        depth: rootNode.depth + 1,
        title: 'Existing Custom Subunit',
        slug: definition.slug,
      ),
    );

    await subunitSeeder.seed();

    expect(repository.nodes['existing-custom-subunit']!.title,
        'Existing Custom Subunit');
    expect(
      repository.nodes.values.where(
        (node) => node.parentUuid == root.uuid && node.slug == definition.slug,
      ),
      hasLength(1),
    );
  });
}
