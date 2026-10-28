import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/library/data/topic_packages/models/topic_package.dart';
import 'package:medvault_app/features/library/data/topic_packages/models/topic_package_validator.dart';

Map<String, dynamic> validPackageJson() => {
      'schemaVersion': '1.0',
      'topic': {
        'id': 'topic-test',
        'title': 'Example Topic',
        'specialty': 'Example Specialty',
        'contentVersion': 1,
        'reviewStatus': 'draft',
        'futureMetadata': {'preserved': true},
      },
      'pages': [
        {
          'id': 'page-1',
          'type': 'overview',
          'title': 'Introduction',
          'sourceIds': ['source-1'],
          'blocks': [
            {
              'id': 'block-1',
              'type': 'rich_text',
              'text': 'Synthetic test text.',
              'futureField': 42,
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

void main() {
  group('TopicPackage.fromJson', () {
    test('parses a valid package and preserves unknown fields', () {
      final package = TopicPackage.fromJson(validPackageJson());

      expect(package.schemaVersion, '1.0');
      expect(package.topic.id, 'topic-test');
      expect(package.pages, hasLength(1));
      expect(package.pages.single.blocks.single.type, 'rich_text');
      expect(package.pages.single.blocks.single.rawJson['futureField'], 42);
      expect(
        package.toJson()['topic']['futureMetadata']['preserved'],
        isTrue,
      );
    });

    test('rejects a missing pages array', () {
      final json = validPackageJson()..remove('pages');

      expect(
        () => TopicPackage.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-object content block', () {
      final json = validPackageJson();
      (json['pages'] as List).first['blocks'] = ['not an object'];

      expect(
        () => TopicPackage.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('TopicPackageValidator', () {
    const validator = TopicPackageValidator();

    test('accepts a structurally valid package', () {
      final package = TopicPackage.fromJson(validPackageJson());

      final result = validator.validate(package);

      expect(result.isValid, isTrue, reason: '${result.issues}');
    });

    test('reports duplicate page and block IDs', () {
      final json = validPackageJson();
      final pages = json['pages'] as List;
      pages.add({
        'id': 'page-1',
        'type': 'overview',
        'title': 'Duplicate page',
        'blocks': [
          {
            'id': 'block-1',
            'type': 'rich_text',
            'text': 'Synthetic text.',
          },
        ],
      });

      final result =
          validator.validate(TopicPackage.fromJson(json));

      expect(result.isValid, isFalse);
      expect(
        result.issues.any((issue) => issue.message.contains('Duplicate page ID')),
        isTrue,
      );
      expect(
        result.issues.any((issue) => issue.message.contains('Duplicate block ID')),
        isTrue,
      );
    });

    test('reports unresolved and repeated source references', () {
      final json = validPackageJson();
      (json['pages'] as List).first['sourceIds'] = [
        'missing-source',
        'source-1',
        'source-1',
      ];

      final result =
          validator.validate(TopicPackage.fromJson(json));

      expect(result.isValid, isFalse);
      expect(
        result.issues.any((issue) => issue.message.contains('does not exist')),
        isTrue,
      );
      expect(
        result.issues.any((issue) => issue.message.contains('more than once')),
        isTrue,
      );
    });

    test('reports unsupported block types', () {
      final json = validPackageJson();
      (json['pages'] as List).first['blocks'] = [
        {'id': 'block-1', 'type': 'unknown_block'},
      ];

      final result =
          validator.validate(TopicPackage.fromJson(json));

      expect(result.isValid, isFalse);
      expect(
        result.issues.any((issue) => issue.message.contains('Unknown block type')),
        isTrue,
      );
    });

    test('reports unsupported schema versions', () {
      final json = validPackageJson()..['schemaVersion'] = '99.0';

      final result =
          validator.validate(TopicPackage.fromJson(json));

      expect(result.isValid, isFalse);
      expect(
        result.issues.any((issue) => issue.path == 'schemaVersion'),
        isTrue,
      );
    });

    test('rejects unsupported page types and review statuses', () {
      final json = validPackageJson();
      (json['pages'] as List).first['type'] = 'not-a-page';
      (json['topic'] as Map)['reviewStatus'] = 'unreviewed';

      final result = validator.validate(TopicPackage.fromJson(json));

      expect(result.isValid, isFalse);
      expect(result.issues.any((issue) => issue.path == 'pages[0].type'), isTrue);
      expect(result.issues.any((issue) => issue.path == 'topic.reviewStatus'), isTrue);
    });

    test('rejects invalid IDs and short topic titles', () {
      final json = validPackageJson();
      (json['topic'] as Map)
        ..['id'] = 'Invalid ID'
        ..['title'] = 'OK';
      (json['pages'] as List).first['id'] = 'Page 1';

      final result = validator.validate(TopicPackage.fromJson(json));

      expect(result.isValid, isFalse);
      expect(result.issues.any((issue) => issue.path == 'topic.id'), isTrue);
      expect(result.issues.any((issue) => issue.path == 'topic.title'), isTrue);
      expect(result.issues.any((issue) => issue.path == 'pages[0].id'), isTrue);
    });

    test('rejects packages with more than 15 pages', () {
      final json = validPackageJson();
      final pages = json['pages'] as List;
      for (var i = 2; i <= 16; i++) {
        pages.add({
          'id': 'page-$i',
          'type': 'overview',
          'title': 'Synthetic page $i',
          'blocks': [
            {'id': 'block-$i', 'type': 'rich_text', 'text': 'Synthetic text.'},
          ],
        });
      }

      final result = validator.validate(TopicPackage.fromJson(json));

      expect(result.isValid, isFalse);
      expect(result.issues.any((issue) => issue.path == 'pages'), isTrue);
    });

    test('requires source organization and valid source metadata', () {
      final json = validPackageJson();
      final source = (json['sources'] as List).first as Map;
      source
        ..remove('organization')
        ..['sourceType'] = 'invalid'
        ..['status'] = 'unverified';

      final result = validator.validate(TopicPackage.fromJson(json));

      expect(result.isValid, isFalse);
      expect(result.issues.any((issue) => issue.path == 'sources[0].organization'), isTrue);
      expect(result.issues.any((issue) => issue.path == 'sources[0].sourceType'), isTrue);
      expect(result.issues.any((issue) => issue.path == 'sources[0].status'), isTrue);
    });
  });
}
