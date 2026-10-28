import 'package:isar/isar.dart';

part 'learning_resource_model.g.dart';

/// Local metadata for a learning resource stored in MedVault's file directory.
///
/// The PDF bytes are stored separately from Isar. [relativeFilePath] is
/// resolved against MedVault's managed resource directory at runtime.
@collection
class LearningResourceModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index()
  late String topicUuid;

  late String title;

  late String originalFileName;

  @Index(unique: true)
  late String relativeFilePath;

  late int fileSizeBytes;

  late DateTime importedAt;
}
