import 'package:isar/isar.dart';

import '../../domain/entities/learning_resource.dart';
import '../../domain/repositories/learning_resource_repository.dart';
import '../models/learning_resource_mapper.dart';
import '../models/learning_resource_model.dart';

/// Isar-backed persistence for locally stored learning-resource metadata.
class IsarLearningResourceRepository implements LearningResourceRepository {
  IsarLearningResourceRepository(this._isar);

  final Isar _isar;

  @override
  Future<void> save(LearningResource resource) async {
    final model = LearningResourceMapper.toModel(resource);

    final existing = await _isar.learningResourceModels
        .where()
        .uuidEqualTo(model.uuid)
        .findFirst();

    if (existing != null) {
      model.id = existing.id;
    }

    await _isar.writeTxn(() async {
      await _isar.learningResourceModels.put(model);
    });
  }

  @override
  Future<LearningResource?> getByUuid(String uuid) async {
    final model = await _isar.learningResourceModels
        .where()
        .uuidEqualTo(uuid)
        .findFirst();

    if (model == null) return null;
    return LearningResourceMapper.toDomain(model);
  }

  @override
  Future<List<LearningResource>> getByTopicUuid(String topicUuid) async {
    final models = await _isar.learningResourceModels
        .where()
        .topicUuidEqualTo(topicUuid)
        .sortByTitle()
        .findAll();

    return models.map(LearningResourceMapper.toDomain).toList();
  }

  @override
  Future<List<LearningResource>> getAll() async {
    final models = await _isar.learningResourceModels.where().findAll();
    return models.map(LearningResourceMapper.toDomain).toList();
  }

  @override
  Future<void> deleteByUuid(String uuid) async {
    await _isar.writeTxn(() async {
      await _isar.learningResourceModels.where().uuidEqualTo(uuid).deleteAll();
    });
  }
}
