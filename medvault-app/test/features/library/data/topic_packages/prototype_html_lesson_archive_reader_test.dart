import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/library/data/topic_packages/prototype_html_lesson_archive_reader.dart';

void main() {
  const reader = PrototypeHtmlLessonArchiveReader();

  Uint8List buildZip(Map<String, String> entries) {
    final archive = Archive();
    for (final entry in entries.entries) {
      final bytes = utf8.encode(entry.value);
      archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  const html = '<!doctype html><html><body>Lesson preview</body></html>';

  test('reads a root-level index.html', () {
    final result = reader.read(buildZip({'index.html': html}));
    expect(result.html, html);
  });

  test('reads preview/index.html from a lesson bundle', () {
    final result = reader.read(buildZip({
      'preview/index.html': html,
      'content/malaria.json': '{"title":"Synthetic lesson"}',
      'content/topic.schema.json': '{"type":"object"}',
      'assets/example.svg': '<svg></svg>',
    }));

    expect(result.html, html);
  });

  test('rejects ZIPs without an HTML entry', () {
    final zip = buildZip({
      'content/malaria.json': '{"title":"Synthetic lesson"}',
    });

    expect(() => reader.read(zip), throwsFormatException);
  });

  test('rejects incomplete HTML documents', () {
    final zip = buildZip({
      'preview/index.html': '<html><body>Incomplete',
    });

    expect(() => reader.read(zip), throwsFormatException);
  });
}
