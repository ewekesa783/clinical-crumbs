import '../entities/learning_resource.dart';

/// Repository boundary for metadata belonging to locally stored resources.
abstract class LearningResourceRepository {
  Future<void> save(LearningResource resource);

  Future<LearningResource?> getByUuid(String uuid);

  Future<List<LearningResource>> getByTopicUuid(String topicUuid);

  Future<List<LearningResource>> getAll();

  Future<void> deleteByUuid(String uuid);
}
