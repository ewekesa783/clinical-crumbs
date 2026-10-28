import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// An in-memory, read-only archive containing a self-contained HTML lesson.
class PrototypeHtmlLessonArchive {
  const PrototypeHtmlLessonArchive({required this.html});

  final String html;
}

/// Reads a ZIP whose root contains a standalone index.html document.
///
/// The document may contain inline CSS and JavaScript. No files are written
/// to disk and this reader does not interact with Isar.
class PrototypeHtmlLessonArchiveReader {
  const PrototypeHtmlLessonArchiveReader();

  PrototypeHtmlLessonArchive read(Uint8List zipBytes) {
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

      if (!entry.isFile) continue;

      if (files.containsKey(name)) {
        throw const FormatException('Invalid or duplicate ZIP entry.');
      }
      files[name] = entry;
    }

    final htmlFile = files['index.html'] ?? files['preview/index.html'];
    if (htmlFile == null) {
      throw const FormatException(
        'An HTML lesson ZIP must contain index.html or preview/index.html.',
      );
    }

    final String html;
    try {
      html = utf8.decode(htmlFile.content as List<int>);
    } on FormatException {
      throw const FormatException('The lesson HTML file is not valid UTF-8 text.');
    }

    final trimmed = html.trimLeft().toLowerCase();
    if (trimmed.isEmpty ||
        !trimmed.contains('<html') ||
        !trimmed.contains('</html>')) {
      throw const FormatException(
        'index.html must contain a complete HTML document.',
      );
    }

    return PrototypeHtmlLessonArchive(html: html);
  }
}
