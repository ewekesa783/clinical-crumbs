import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/features/library/data/models/learning_resource_model.dart';
import 'package:medvault_app/features/library/data/repositories/isar_learning_resource_repository.dart';
import 'package:medvault_app/features/library/domain/entities/learning_resource.dart';

void main() {
  late Isar isar;
  late Directory tempDir;
  late IsarLearningResourceRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('medvault_resource_test_');
    isar = await Isar.open(
      [LearningResourceModelSchema],
      directory: tempDir.path,
    );
    repository = IsarLearningResourceRepository(isar);
  });

  tearDown(() async {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  LearningResource makeResource({
    required String uuid,
    required String topicUuid,
    required String title,
    String relativeFilePath = 'pdfs/resource.pdf',
    int fileSizeBytes = 1024,
    DateTime? importedAt,
  }) {
    return LearningResource(
      uuid: uuid,
      topicUuid: topicUuid,
      title: title,
      originalFileName: '$title.pdf',
      relativeFilePath: relativeFilePath,
      fileSizeBytes: fileSizeBytes,
      importedAt: importedAt ?? DateTime.utc(2026, 1, 1),
    );
  }

  test('save and getByUuid persist resource metadata', () async {
    await repository.save(makeResource(
      uuid: 'resource-1',
      topicUuid: 'topic-1',
      title: 'Cardiology diagrams',
    ));

    final fetched = await repository.getByUuid('resource-1');

    expect(fetched, isNotNull);
    expect(fetched!.title, 'Cardiology diagrams');
    expect(fetched.topicUuid, 'topic-1');
    expect(fetched.originalFileName, 'Cardiology diagrams.pdf');
    expect(fetched.relativeFilePath, 'pdfs/resource.pdf');
    expect(fetched.fileSizeBytes, 1024);
  });

  test('getByTopicUuid returns only matching resources sorted by title',
      () async {
    await repository.save(makeResource(
      uuid: 'resource-z',
      topicUuid: 'topic-1',
      title: 'Zoology diagrams',
      relativeFilePath: 'pdfs/z.pdf',
    ));
    await repository.save(makeResource(
      uuid: 'resource-other',
      topicUuid: 'topic-2',
      title: 'Other topic resource',
      relativeFilePath: 'pdfs/other.pdf',
    ));
    await repository.save(makeResource(
      uuid: 'resource-a',
      topicUuid: 'topic-1',
      title: 'Anatomy diagrams',
      relativeFilePath: 'pdfs/a.pdf',
    ));

    final resources = await repository.getByTopicUuid('topic-1');

    expect(
      resources.map((resource) => resource.uuid).toList(),
      ['resource-a', 'resource-z'],
    );
  });

  test('saving an existing UUID updates metadata without duplicating it',
      () async {
    await repository.save(makeResource(
      uuid: 'resource-1',
      topicUuid: 'topic-1',
      title: 'Original title',
    ));

    await repository.save(makeResource(
      uuid: 'resource-1',
      topicUuid: 'topic-1',
      title: 'Updated title',
      relativeFilePath: 'pdfs/updated.pdf',
      fileSizeBytes: 2048,
      importedAt: DateTime.utc(2026, 1, 2),
    ));

    final fetched = await repository.getByUuid('resource-1');
    final resources = await repository.getByTopicUuid('topic-1');

    expect(fetched, isNotNull);
    expect(fetched!.title, 'Updated title');
    expect(fetched.relativeFilePath, 'pdfs/updated.pdf');
    expect(fetched.fileSizeBytes, 2048);
    expect(resources, hasLength(1));
  });

  test('deleteByUuid removes metadata', () async {
    await repository.save(makeResource(
      uuid: 'resource-1',
      topicUuid: 'topic-1',
      title: 'Learning resource',
    ));

    await repository.deleteByUuid('resource-1');

    expect(await repository.getByUuid('resource-1'), isNull);
    expect(await repository.getByTopicUuid('topic-1'), isEmpty);
  });
}
