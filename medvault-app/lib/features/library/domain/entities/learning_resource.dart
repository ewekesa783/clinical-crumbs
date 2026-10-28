/// The supported formats for locally stored learning resources.
enum LearningResourceFormat { pdf, htmlLesson }

/// Metadata for a locally stored learning resource, separate from its file
/// contents and independent of the persistence implementation.
class LearningResource {
  const LearningResource({
    required this.uuid,
    required this.topicUuid,
    required this.title,
    required this.originalFileName,
    required this.relativeFilePath,
    required this.fileSizeBytes,
    required this.importedAt,
  });

  final String uuid;
  final String topicUuid;
  final String title;
  final String originalFileName;
  final String relativeFilePath;
  final int fileSizeBytes;
  final DateTime importedAt;

  /// Determines the resource format from its canonical managed storage path.
  ///
  /// Existing database records remain compatible because no new persisted
  /// field is required.
  LearningResourceFormat get format {
    final segments = relativeFilePath.split(RegExp(r'[/\\]'));
    if (segments.length == 3 &&
        segments[0] == 'learning_resources' &&
        segments[1] == 'html_lessons') {
      return LearningResourceFormat.htmlLesson;
    }
    return LearningResourceFormat.pdf;
  }
}
