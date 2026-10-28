import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Read-only reader for a single Clinical Crumbs prototype lesson ZIP.
///
/// Expected layout:
/// - lesson.json
/// - assets/cover.webp (optional)
/// - assets/diagrams/... (optional)
///
/// All content is kept in memory. This reader does not persist data or
/// interact with Isar.
class PrototypeLessonArchive {
  PrototypeLessonArchive({
    required this.lesson,
    required this.assets,
  });

  final Map<String, dynamic> lesson;
  final Map<String, Uint8List> assets;

  Uint8List? assetBytes(String packagePath) => assets[packagePath];
}

class PrototypeLessonArchiveReader {
  const PrototypeLessonArchiveReader();

  PrototypeLessonArchive read(Uint8List zipBytes) {
    if (zipBytes.isEmpty) {
      throw const FormatException('The lesson ZIP is empty.');
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      throw const FormatException('The lesson ZIP could not be decoded.');
    }

    final files = <String, ArchiveFile>{};

    for (final entry in archive.files) {
      var name = entry.name;
      if (!entry.isFile && name.endsWith('/')) {
        name = name.substring(0, name.length - 1);
      }

      if (name.startsWith('/') ||
          name.contains(r'\\') ||
          name.split('/').any(
                (segment) =>
                    segment.isEmpty || segment == '.' || segment == '..',
              )) {
        throw const FormatException('Invalid ZIP entry path.');
      }

      // ZIPs created from folders commonly include directory records.
      if (!entry.isFile) continue;

      if (files.containsKey(name)) {
        throw const FormatException('Invalid or duplicate ZIP entry.');
      }
      files[name] = entry;
    }

    ArchiveFile? lessonFile = files['lesson.json'];

    // Support the actual bundle layout: content/<lesson>.json.
    if (lessonFile == null) {
      final candidates = files.entries
          .where(
            (entry) =>
                entry.key.startsWith('content/') &&
                entry.key.endsWith('.json') &&
                !entry.key.endsWith('/topic.schema.json'),
          )
          .toList();

      if (candidates.length == 1) {
        lessonFile = candidates.single.value;
      }
    }

    if (lessonFile == null) {
      throw const FormatException(
        'The ZIP must contain lesson.json or one lesson JSON under content/.',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(
        utf8.decode(lessonFile.content as List<int>),
      );
    } on FormatException {
      throw const FormatException('lesson.json is not valid JSON.');
    }

    if (decoded is! Map) {
      throw const FormatException('lesson.json must contain a JSON object.');
    }

    final Map<String, dynamic> lesson;
    try {
      lesson = Map<String, dynamic>.from(decoded);
    } on TypeError {
      throw const FormatException('lesson.json must use string keys.');
    }

    if (lesson['schema_version'] is! String ||
        lesson['topic_id'] is! String ||
        (lesson['topic_id'] as String).trim().isEmpty ||
        lesson['title'] is! String ||
        (lesson['title'] as String).trim().isEmpty ||
        lesson['pages'] is! List ||
        (lesson['pages'] as List).isEmpty) {
      throw const FormatException(
        'lesson.json is missing required lesson fields.',
      );
    }

    final pages = lesson['pages'] as List;
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      if (page is! Map ||
          page['id'] is! String ||
          page['type'] is! String ||
          page['title'] is! String) {
        throw FormatException(
          'pages[$i] must contain string fields "id", "type", and "title".',
        );
      }
    }

    final assets = <String, Uint8List>{};
    for (final entry in files.entries) {
      if (!entry.key.startsWith('assets/')) continue;

      final path = entry.key.substring('assets/'.length);
      if (path.isEmpty) {
        throw const FormatException('Invalid asset path.');
      }

      assets[entry.key] = Uint8List.fromList(
        entry.value.content as List<int>,
      );
    }

    return PrototypeLessonArchive(
      lesson: lesson,
      assets: assets,
    );
  }
}
