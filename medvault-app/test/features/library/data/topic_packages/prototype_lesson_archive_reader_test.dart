import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/library/data/topic_packages/prototype_lesson_archive_reader.dart';

void main() {
  const reader = PrototypeLessonArchiveReader();

  Uint8List buildZip(Map<String, List<int>> entries) {
    final archive = Archive();
    for (final entry in entries.entries) {
      archive.addFile(
        ArchiveFile(entry.key, entry.value.length, entry.value),
      );
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  List<int> lessonBytes({
    String title = 'Test lesson',
    Object? pages,
  }) {
    return utf8.encode(jsonEncode({
      'schema_version': '1.0',
      'topic_id': 'test-topic',
      'title': title,
      'pages': pages ??
          [
            {'id': 'cover', 'type': 'cover', 'title': 'Cover'},
          ],
    }));
  }

  test('reads lesson JSON and extracts bundled asset bytes', () {
    final image = <int>[0x52, 0x49, 0x46, 0x46, 0x01, 0x02];
    final zip = buildZip({
      'lesson.json': lessonBytes(),
      'assets/cover.webp': image,
      'assets/diagrams/example.webp': [0x01, 0x02, 0x03],
    });

    final result = reader.read(zip);

    expect(result.lesson['title'], 'Test lesson');
    expect(result.assets.keys, contains('assets/cover.webp'));
    expect(result.assetBytes('assets/cover.webp'), image);
    expect(
      result.assetBytes('assets/diagrams/example.webp'),
      [0x01, 0x02, 0x03],
    );
    expect(result.assetBytes('missing.webp'), isNull);
  });

  test('reads a lesson from content/ and preserves bundled assets', () {
    final image = <int>[0x01, 0x02, 0x03];
    final zip = buildZip({
      'content/malaria.json': lessonBytes(title: 'Synthetic bundle lesson'),
      'content/topic.schema.json': utf8.encode(
        jsonEncode({'title': 'Schema, not lesson content'}),
      ),
      'assets/illustrations/example.webp': image,
      'preview/index.html': utf8.encode(
        '<!doctype html><html><body>Preview</body></html>',
      ),
    });

    final result = reader.read(zip);

    expect(result.lesson['title'], 'Synthetic bundle lesson');
    expect(
      result.assetBytes('assets/illustrations/example.webp'),
      image,
    );
  });

  test('rejects an empty ZIP input', () {
    expect(
      () => reader.read(Uint8List(0)),
      throwsFormatException,
    );
  });

  test('rejects a ZIP without lesson.json', () {
    final zip = buildZip({
      'assets/cover.webp': [0x01],
    });

    expect(() => reader.read(zip), throwsFormatException);
  });

  test('rejects invalid lesson JSON', () {
    final zip = buildZip({
      'lesson.json': utf8.encode('{not json'),
    });

    expect(() => reader.read(zip), throwsFormatException);
  });

  test('rejects unsafe ZIP entry paths', () {
    final zip = buildZip({
      'lesson.json': lessonBytes(),
      '../outside.json': utf8.encode('{}'),
    });

    expect(() => reader.read(zip), throwsFormatException);
  });

  test('rejects lessons with malformed page entries', () {
    final zip = buildZip({
      'lesson.json': lessonBytes(pages: [
        {'id': 'missing-type', 'title': 'Invalid page'},
      ]),
    });

    expect(() => reader.read(zip), throwsFormatException);
  });
}
