import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/citation_model.dart';
import 'package:medvault_app/features/library/data/repositories/isar_citation_repository.dart';
import 'package:medvault_app/features/library/domain/entities/citation.dart';

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: DateTime.utc(2026, 1, 1),
      isDirty: false,
      isDeleted: false,
      deviceId: 'device-1',
      syncRevision: 1,
    );

Citation _citation(String uuid, String title) => Citation(
      uuid: uuid,
      sourceType: SourceType.textbook,
      title: title,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: _sync(),
    );

void main() {
  late Isar isar;
  late Directory tempDir;
  late IsarCitationRepository repository;

  setUp(async () {
    tempDir = await Directory.systemTemp.createTemp('medvault_isar_test_');
    isar = await Isar.open([CitationModelSchema], directory: tempDir.path);
    repository = IsarCitationRepository(isar);
  });

  tearDown(async () {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('getByUuids preserves order, multiplicity, and omits missing', async () {
    await repository.save(_citation('cite-1', 'First'));
    await repository.save(_citation('cite-2', 'Second'));

    final result = await repository.getByUuids(
      ['cite-2', 'cite-1', 'cite-2', 'missing-uuid'],
    );

    expect(result.map((c) => c.uuid).toList(), ['cite-2', 'cite-1', 'cite-2']);
  });
}
