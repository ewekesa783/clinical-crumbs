import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/library/data/topic_packages/topic_package_loader.dart';

Map<String, dynamic> validPackageJson() => {
      'schemaVersion': '1.0',
      'topic': {
        'id': 'topic-test',
        'title': 'Example Topic',
        'specialty': 'Example Specialty',
        'contentVersion': 1,
        'reviewStatus': 'draft',
      },
      'pages': [
        {
          'id': 'page-1',
          'type': 'overview',
          'title': 'Introduction',
          'blocks': [
            {
              'id': 'block-1',
              'type': 'rich_text',
              'text': 'Synthetic test text.',
            },
          ],
        },
      ],
      'sources': [
        {
          'id': 'source-1',
          'title': 'Synthetic Reference',
          'organization': 'Synthetic Organization',
          'sourceType': 'other',
          'status': 'verified',
        },
      ],
    };

List<int> encodedPackage(Map<String, dynamic> json) =>
    utf8.encode(jsonEncode(json));

void main() {
  const loader = TopicPackageLoader();

  test('loads a valid package without changing its JSON fields', () {
    final json = validPackageJson();

    final package = loader.loadBytes(encodedPackage(json));

    expect(package.schemaVersion, '1.0');
    expect(package.topic.id, 'topic-test');
    expect(package.pages.single.blocks.single.type, 'rich_text');
    expect(package.toJson(), json);
  });

  test('rejects empty bytes', () {
    expect(
      () => loader.loadBytes(const []),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects malformed JSON', () {
    expect(
      () => loader.loadBytes(utf8.encode('{invalid json')),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects a non-object JSON root', () {
    expect(
      () => loader.loadBytes(utf8.encode('[]')),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects a package that fails structural validation', () {
    final json = validPackageJson();
    (json['topic'] as Map)['reviewStatus'] = 'not-a-status';

    expect(
      () => loader.loadBytes(encodedPackage(json)),
      throwsA(isA<TopicPackageLoadException>()),
    );
  });

  test('reports validation issues in the load exception', () {
    final json = validPackageJson();
    (json['pages'] as List).first['type'] = 'not-a-page';

    try {
      loader.loadBytes(encodedPackage(json));
      fail('Expected package validation to fail.');
    } on TopicPackageLoadException catch (error) {
      expect(error.message, contains('pages[0].type'));
      expect(error.message, contains('not-a-page'));
    }
  });
}
