import 'dart:convert';

import 'models/topic_package.dart';
import 'models/topic_package_validator.dart';

/// Loads and validates a topic package without writing to app storage.
///
/// File selection, persistence, and clinical review are intentionally outside
/// this class. A package is returned only when structural validation succeeds.
class TopicPackageLoader {
  const TopicPackageLoader({
    this.validator = const TopicPackageValidator(),
  });

  final TopicPackageValidator validator;

  TopicPackage loadBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('The selected file is empty.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException catch (error) {
      throw FormatException('The file is not valid UTF-8 JSON: ${error.message}');
    }

    if (decoded is! Map) {
      throw const FormatException(
        'The JSON root must be an object containing a topic package.',
      );
    }

    final Map<String, dynamic> json;
    try {
      json = Map<String, dynamic>.from(decoded);
    } on TypeError {
      throw const FormatException(
        'The topic package JSON object must have string keys.',
      );
    }

    final package = TopicPackage.fromJson(json);
    final result = validator.validate(package);

    if (!result.isValid) {
      throw TopicPackageLoadException(result);
    }

    return package;
  }
}

class TopicPackageLoadException implements Exception {
  const TopicPackageLoadException(this.validationResult);

  final TopicPackageValidationResult validationResult;

  String get message => validationResult.issues
      .map((issue) => issue.toString())
      .join('\n');

  @override
  String toString() => 'TopicPackageLoadException: $message';
}
