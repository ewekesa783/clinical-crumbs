import 'package:file_picker/file_picker.dart';

import 'models/topic_package.dart';
import 'topic_package_loader.dart';

typedef TopicPackagePickFiles = Future<FilePickerResult?> Function();

Future<FilePickerResult?> _pickJsonFile() {
  return FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    allowMultiple: false,
    withData: true,
  );
}

/// Selects and validates a topic-package JSON file.
///
/// This service never persists package data or modifies the live library.
/// Cancellation returns null; invalid files throw a format or validation error.
class TopicPackageFilePicker {
  const TopicPackageFilePicker({
    this.loader = const TopicPackageLoader(),
    this.pickFiles = _pickJsonFile,
  });

  final TopicPackageLoader loader;
  final TopicPackagePickFiles pickFiles;

  Future<TopicPackage?> pickAndLoad() async {
    final selection = await pickFiles();

    if (selection == null) return null;

    final bytes = selection.files.single.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException(
        'The selected topic-package file could not be read or is empty.',
      );
    }

    return loader.loadBytes(bytes);
  }
}
