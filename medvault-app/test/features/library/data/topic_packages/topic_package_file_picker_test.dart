import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/library/data/topic_packages/topic_package_file_picker.dart';
import 'package:medvault_app/features/library/data/topic_packages/topic_package_loader.dart';

Map<String, dynamic> validPackageJson() => {
      'schemaVersion': '1.0',
      'topic': {
        'id': 'picker-test',
        'title': 'Synthetic Topic',
        'specialty': 'Synthetic Specialty',
        'contentVersion': 1,
        'reviewStatus': 'draft',
      },
      'pages': [
        {
          'id': 'page-1',
          'type': 'overview',
          'title': 'Synthetic Overview',
          'blocks': [
            {
              'id': 'block-1',
              'type': 'rich_text',
              'text': 'Synthetic test content.',
            },
          ],
        },
      ],
      'sources': [
        {
          'id': 'source-1',
          'title': 'Synthetic Source',
          'organization': 'Synthetic Organization',
          'sourceType': 'other',
          'status': 'verified',
        },
      ],
    };

PlatformFile selectedFile(List<int>? bytes) => PlatformFile(
      name: 'synthetic-topic.json',
      size: bytes?.length ?? 0,
      bytes: bytes == null ? null : Uint8List.fromList(bytes),
    );

void main() {
  test('loads a valid selected JSON package', () async {
    final bytes = utf8.encode(jsonEncode(validPackageJson()));
    final picker = TopicPackageFilePicker(
      pickFiles: () async => FilePickerResult([selectedFile(bytes)]),
    );

    final package = await picker.pickAndLoad();

    expect(package, isNotNull);
    expect(package!.topic.id, 'picker-test');
    expect(package.toJson(), validPackageJson());
  });

  test('returns null when the user cancels selection', () async {
    final picker = TopicPackageFilePicker(
      pickFiles: () async => null,
    );

    expect(await picker.pickAndLoad(), isNull);
  });

  test('rejects a selected file with missing bytes', () async {
    final picker = TopicPackageFilePicker(
      pickFiles: () async => FilePickerResult([selectedFile(null)]),
    );

    await expectLater(
      picker.pickAndLoad(),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects an empty selected file', () async {
    final picker = TopicPackageFilePicker(
      pickFiles: () async => FilePickerResult([selectedFile(const [])]),
    );

    await expectLater(
      picker.pickAndLoad(),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects an invalid topic package', () async {
    final json = validPackageJson();
    (json['topic'] as Map)['reviewStatus'] = 'invalid';
    final bytes = utf8.encode(jsonEncode(json));
    final picker = TopicPackageFilePicker(
      pickFiles: () async => FilePickerResult([selectedFile(bytes)]),
    );

    await expectLater(
      picker.pickAndLoad(),
      throwsA(isA<TopicPackageLoadException>()),
    );
  });
}
