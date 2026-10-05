import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/taxonomy_node_model.dart';
import 'package:medvault_app/features/library/data/repositories/isar_taxonomy_repository.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'device-1',
      syncRevision: 1,
    );

void main() {
  late Isar isar;
  late Directory tempDir;
  late IsarTaxonomyRepository repository;

  setUp(() async {
    // A real temp-directory Isar instance is used here rather than an
    // in-memory instance; see the corrected repository-test comment
    // established during MV-IP-001 Task A.1A.
    tempDir = await Directory.systemTemp.createTemp('medvault_isar_test_');
    isar = await Isar.open(
      [TaxonomyNodeModelSchema],
      directory: tempDir.path,
    );
    repository = IsarTaxonomyRepository(isar);
  });

  tearDown(() async {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('save then getByUuid returns the inserted node', () async {
    final node = TaxonomyNode(
      uuid: 'node-1',
      parentUuid: null,
      path: 'node-1',
      depth: 0,
      nodeType: NodeType.subject,
      title: 'Cardiology',
      slug: 'cardiology',
      sortOrder: 0,
      noteCount: 0,
      isUserCreated: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );

    await repository.save(node);
    final fetched = await repository.getByUuid('node-1');

    expect(fetched, isNotNull);
    expect(fetched!.title, 'Cardiology');
  });

  test('getChildren resolves parent-child relationships', () async {
    final parent = TaxonomyNode(
      uuid: 'parent-1',
      parentUuid: null,
      path: 'parent-1',
      depth: 0,
      nodeType: NodeType.subject,
      title: 'Cardiology',
      slug: 'cardiology',
      sortOrder: 0,
      noteCount: 0,
      isUserCreated: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );
    final child = TaxonomyNode(
      uuid: 'child-1',
      parentUuid: 'parent-1',
      path: 'parent-1/child-1',
      depth: 1,
      nodeType: NodeType.topic,
      title: 'Arrhythmias',
      slug: 'arrhythmias',
      sortOrder: 0,
      noteCount: 0,
      isUserCreated: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );

    await repository.save(parent);
    await repository.save(child);

    final children = await repository.getChildren('parent-1');
    expect(children, hasLength(1));
    expect(children.first.uuid, 'child-1');
  });

  test('save rejects a duplicate-slug sibling', () async {
    final first = TaxonomyNode(
      uuid: 'node-1',
      parentUuid: 'parent-1',
      path: 'parent-1/node-1',
      depth: 1,
      nodeType: NodeType.topic,
      title: 'Arrhythmias',
      slug: 'arrhythmias',
      sortOrder: 0,
      noteCount: 0,
      isUserCreated: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );
    final duplicateSlug = TaxonomyNode(
      uuid: 'node-2',
      parentUuid: 'parent-1',
      path: 'parent-1/node-2',
      depth: 1,
      nodeType: NodeType.topic,
      title: 'Arrhythmias (duplicate)',
      slug: 'arrhythmias',
      sortOrder: 1,
      noteCount: 0,
      isUserCreated: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );

    await repository.save(first);
    expect(() => repository.save(duplicateSlug), throwsStateError);
  });
}
