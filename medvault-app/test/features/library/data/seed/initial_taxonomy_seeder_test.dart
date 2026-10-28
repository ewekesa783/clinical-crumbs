import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/storage/device_identity.dart';
import 'package:medvault_app/core/sync/sync_metadata_factory.dart';
import 'package:medvault_app/core/time/clock.dart';
import 'package:medvault_app/features/library/data/seed/initial_taxonomy_seeder.dart';
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

TaxonomyNode _existingRoot({
  required String uuid,
  required String title,
  required String slug,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return TaxonomyNode(
    uuid: uuid,
    parentUuid: null,
    path: uuid,
    depth: 0,
    nodeType: NodeType.subject,
    title: title,
    slug: slug,
    sortOrder: 0,
    noteCount: 0,
    isUserCreated: false,
    createdAt: now,
    updatedAt: now,
    sync: SyncMetadataFactory(
      deviceIdentity: DeviceIdentity(deviceId: 'test-device'),
      clock: _FixedClock(),
    )(),
  );
}

void main() {
  late _FakeTaxonomyRepository repository;
  late _FixedClock clock;
  late InitialTaxonomySeeder seeder;

  setUp(() {
    repository = _FakeTaxonomyRepository();
    clock = _FixedClock();
    seeder = InitialTaxonomySeeder(
      taxonomyRepository: repository,
      syncMetadataFactory: SyncMetadataFactory(
        deviceIdentity: DeviceIdentity(deviceId: 'test-device'),
        clock: clock,
      ),
      clock: clock,
    );
  });

  test('seeds the six initial units as ordered root subject nodes', () async {
    await seeder.seed();

    final roots = (await repository.getAll())
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    expect(roots, hasLength(6));
    expect(
      roots.map((node) => node.title).toList(),
      [
        'Medicine',
        'Surgery',
        'Obstetrics and Gynaecology',
        'Paediatrics and Child Health',
        'Community Health',
        'Dental',
      ],
    );
    expect(
      roots.map((node) => node.slug).toList(),
      initialTaxonomyUnits.map((unit) => unit.slug).toList(),
    );

    for (final node in roots) {
      expect(node.parentUuid, isNull);
      expect(node.depth, 0);
      expect(node.nodeType, NodeType.subject);
      expect(node.noteCount, 0);
    }
  });

  test('repeated seeding does not create duplicate records', () async {
    await seeder.seed();
    final initialSaveCount = repository.saveCount;

    await seeder.seed();

    expect(repository.nodes, hasLength(6));
    expect(repository.saveCount, initialSaveCount);
  });

  test('fills missing units while preserving existing root records', () async {
    final medicine = initialTaxonomyUnits.first;
    final customisedRoot = _existingRoot(
      uuid: medicine.uuid,
      title: 'My Medicine Library',
      slug: medicine.slug,
    );
    await repository.save(customisedRoot);
    final savesBeforeSeeding = repository.saveCount;

    await seeder.seed();

    expect(repository.nodes, hasLength(6));
    expect(repository.nodes[medicine.uuid]!.title, 'My Medicine Library');
    expect(repository.saveCount - savesBeforeSeeding, 5);

    for (final unit in initialTaxonomyUnits.skip(1)) {
      expect(repository.nodes[unit.uuid]!.title, unit.title);
    }
  });

  test('does not create a duplicate root when its slug already exists',
      () async {
    await repository.save(
      _existingRoot(
        uuid: 'existing-medicine-root',
        title: 'Imported Medicine',
        slug: 'medicine',
      ),
    );

    await seeder.seed();

    expect(repository.nodes, hasLength(6));
    expect(repository.nodes['existing-medicine-root']!.title,
        'Imported Medicine');
    expect(
      repository.nodes.values.where((node) => node.slug == 'medicine'),
      hasLength(1),
    );
  });
}
