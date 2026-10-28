import '../../domain/entities/learning_resource.dart';
import 'learning_resource_model.dart';

class LearningResourceMapper {
  const LearningResourceMapper._();

  static LearningResource toDomain(LearningResourceModel model) {
    return LearningResource(
      uuid: model.uuid,
      topicUuid: model.topicUuid,
      title: model.title,
      originalFileName: model.originalFileName,
      relativeFilePath: model.relativeFilePath,
      fileSizeBytes: model.fileSizeBytes,
      importedAt: model.importedAt,
    );
  }

  static LearningResourceModel toModel(LearningResource resource) {
    return LearningResourceModel()
      ..uuid = resource.uuid
      ..topicUuid = resource.topicUuid
      ..title = resource.title
      ..originalFileName = resource.originalFileName
      ..relativeFilePath = resource.relativeFilePath
      ..fileSizeBytes = resource.fileSizeBytes
      ..importedAt = resource.importedAt;
  }
}
