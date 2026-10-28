import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/storage/device_identity.dart';
import 'package:medvault_app/core/sync/sync_metadata_factory.dart';
import 'package:medvault_app/core/time/clock.dart';
import 'package:medvault_app/features/library/data/seed/initial_taxonomy_seeder.dart';
import 'package:medvault_app/features/library/data/seed/initial_taxonomy_subunit_seeder.dart';
import 'package:medvault_app/features/library/data/seed/initial_taxonomy_topic_seeder.dart';
import 'package:medvault_app/features/library/data/seed/initial_taxonomy_topics.dart';
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
  late InitialTaxonomyTopicSeeder topicSeeder;

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
    topicSeeder = InitialTaxonomyTopicSeeder(
      taxonomyRepository: repository,
      syncMetadataFactory: syncMetadataFactory,
      clock: clock,
    );
  });

  Future<void> seedHierarchy() async {
    await rootSeeder.seed();
    await subunitSeeder.seed();
    await topicSeeder.seed();
  }

  TaxonomyNode makeExistingNode({
    required String uuid,
    required String parentUuid,
    required String path,
    required int depth,
    required String title,
    required String slug,
  }) {
    final now = DateTime.utc(2026, 1, 1);
    return TaxonomyNode(
      uuid: uuid,
      parentUuid: parentUuid,
      path: path,
      depth: depth,
      nodeType: NodeType.topic,
      title: title,
      slug: slug,
      sortOrder: 0,
      noteCount: 0,
      isUserCreated: true,
      createdAt: now,
      updatedAt: now,
      sync: syncMetadataFactory(),
    );
  }

  test('seeds each topic beneath its matching specialty', () async {
    await seedHierarchy();

    for (final definition in initialTaxonomyTopics) {
      final parent = repository.nodes.values.singleWhere(
        (node) =>
            node.nodeType == NodeType.system &&
            node.uuid == definition.parentUuid,
      );
      final topic = repository.nodes[definition.uuid];

      expect(topic, isNotNull, reason: definition.title);
      expect(topic!.parentUuid, parent.uuid, reason: definition.title);
      expect(topic.path, '${parent.path}/${definition.uuid}');
      expect(topic.depth, parent.depth + 1);
      expect(topic.nodeType, NodeType.topic);
      expect(topic.title, definition.title);
      expect(topic.slug, definition.slug);
      expect(topic.noteCount, 0);
      expect(topic.isUserCreated, isFalse);
    }
  });

  test('Movement Disorders and Myopathies are present in Neurology', () async {
    await seedHierarchy();

    final neurology = repository.nodes.values.singleWhere(
      (node) => node.slug == 'neurology',
    );
    final neurologyTopics = repository.nodes.values
        .where((node) => node.parentUuid == neurology.uuid)
        .map((node) => node.title)
        .toSet();

    expect(neurologyTopics, contains('Movement Disorders'));
    expect(neurologyTopics, contains('Myopathies'));
  });

  test('repeated topic seeding does not create duplicate records', () async {
    await seedHierarchy();
    final savedCount = repository.saveCount;
    final nodeCount = repository.nodes.length;

    await topicSeeder.seed();

    expect(repository.nodes, hasLength(nodeCount));
    expect(repository.saveCount, savedCount);
  });

  test('preserves an existing topic with the same UUID', () async {
    await rootSeeder.seed();
    await subunitSeeder.seed();

    final definition = initialTaxonomyTopics.first;
    final parent = repository.nodes.values.singleWhere(
      (node) =>
          node.nodeType == NodeType.system &&
          node.uuid == definition.parentUuid,
    );

    await repository.save(
      makeExistingNode(
        uuid: definition.uuid,
        parentUuid: parent.uuid,
        path: '${parent.path}/${definition.uuid}',
        depth: parent.depth + 1,
        title: 'My Existing Topic',
        slug: definition.slug,
      ),
    );

    await topicSeeder.seed();

    expect(repository.nodes[definition.uuid]!.title, 'My Existing Topic');
    expect(
      repository.nodes.values.where(
        (node) =>
            node.parentUuid == parent.uuid && node.slug == definition.slug,
      ),
      hasLength(1),
    );
  });

  test('does not create a duplicate sibling slug', () async {
    await rootSeeder.seed();
    await subunitSeeder.seed();

    final definition = initialTaxonomyTopics.first;
    final parent = repository.nodes.values.singleWhere(
      (node) =>
          node.nodeType == NodeType.system &&
          node.uuid == definition.parentUuid,
    );

    await repository.save(
      makeExistingNode(
        uuid: 'existing-custom-topic',
        parentUuid: parent.uuid,
        path: '${parent.path}/existing-custom-topic',
        depth: parent.depth + 1,
        title: 'Existing Custom Topic',
        slug: definition.slug,
      ),
    );

    await topicSeeder.seed();

    expect(repository.nodes['existing-custom-topic']!.title,
        'Existing Custom Topic');
    expect(
      repository.nodes.values.where(
        (node) => node.parentUuid == parent.uuid && node.slug == definition.slug,
      ),
      hasLength(1),
    );
  });
}
