import 'topic_package.dart';

class TopicPackageValidationIssue {
  const TopicPackageValidationIssue({
    required this.path,
    required this.message,
  });

  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}

class TopicPackageValidationResult {
  const TopicPackageValidationResult(this.issues);

  final List<TopicPackageValidationIssue> issues;

  bool get isValid => issues.isEmpty;
}

/// Checks schema-level structure and package-internal references.
///
/// This validator does not assess clinical accuracy or grant publication
/// approval. Those require a separate review process.
class TopicPackageValidator {
  const TopicPackageValidator();

  static const supportedSchemaVersion = '1.0';

  static const _pageTypes = {
    'cover',
    'case',
    'overview',
    'concept',
    'classification',
    'clinical',
    'reasoning',
    'investigations',
    'management',
    'recap',
    'quiz',
    'references',
    'custom',
  };

  static const _reviewStatuses = {
    'draft',
    'in_review',
    'approved',
    'published',
    'retired',
  };

  static const _blockTypes = {
    'rich_text',
    'takeaway',
    'image',
    'diagram',
    'comparison',
    'table',
    'flowchart',
    'callout',
    'reveal',
    'clinical_case',
    'question',
    'flashcard',
    'source_note',
  };

  static final _idPattern = RegExp(r'^[a-z0-9-]+$');

  TopicPackageValidationResult validate(TopicPackage package) {
    final issues = <TopicPackageValidationIssue>[];

    void add(String path, String message) {
      issues.add(TopicPackageValidationIssue(path: path, message: message));
    }

    void checkOptionalString(
      Map<String, dynamic> json,
      String key,
      String path, {
      bool nullable = false,
    }) {
      if (!json.containsKey(key)) return;
      final value = json[key];
      if (value is String || (nullable && value == null)) return;
      add(path, 'Must be ${nullable ? 'a string or null' : 'a string'}.');
    }

    if (package.schemaVersion != supportedSchemaVersion) {
      add(
        'schemaVersion',
        'Unsupported schema version "${package.schemaVersion}"; '
            'supported version is "$supportedSchemaVersion".',
      );
    }

    final topic = package.topic;
    if (!_idPattern.hasMatch(topic.id)) {
      add('topic.id', 'Topic ID must match ^[a-z0-9-]+\$.');
    }
    if (topic.title.trim().length < 3) {
      add('topic.title', 'Topic title must contain at least 3 characters.');
    }
    if (topic.specialty.trim().isEmpty) {
      add('topic.specialty', 'Topic specialty must not be empty.');
    }
    if (topic.contentVersion < 1) {
      add('topic.contentVersion', 'Content version must be at least 1.');
    }
    if (!_reviewStatuses.contains(topic.reviewStatus)) {
      add(
        'topic.reviewStatus',
        'Unsupported review status "${topic.reviewStatus}".',
      );
    }

    final topicJson = topic.rawJson;
    final estimatedMinutes = topicJson['estimatedMinutes'];
    if (estimatedMinutes != null &&
        (estimatedMinutes is! int ||
            estimatedMinutes < 1 ||
            estimatedMinutes > 60)) {
      add('topic.estimatedMinutes', 'Must be an integer from 1 to 60.');
    }
    final audience = topicJson['audience'];
    if (audience != null &&
        (audience is! List || audience.any((value) => value is! String))) {
      add('topic.audience', 'Must be an array of strings.');
    }
    checkOptionalString(
      topicJson,
      'reviewedAt',
      'topic.reviewedAt',
      nullable: true,
    );
    checkOptionalString(
      topicJson,
      'reviewerRole',
      'topic.reviewerRole',
      nullable: true,
    );

    if (package.pages.isEmpty) {
      add('pages', 'A topic package must contain at least one page.');
    }
    if (package.pages.length > 15) {
      add('pages', 'A topic package must contain no more than 15 pages.');
    }

    final pageIds = <String>{};
    final blockIds = <String>{};

    for (var i = 0; i < package.pages.length; i++) {
      final page = package.pages[i];
      final path = 'pages[$i]';
      final pageJson = page.rawJson;

      if (!_idPattern.hasMatch(page.id)) {
        add('$path.id', 'Page ID must match ^[a-z0-9-]+\$.');
      } else if (!pageIds.add(page.id)) {
        add('$path.id', 'Duplicate page ID "${page.id}".');
      }

      if (!_pageTypes.contains(page.type)) {
        add('$path.type', 'Unsupported page type "${page.type}".');
      }
      if (page.title.isEmpty) {
        add('$path.title', 'Page title must not be empty.');
      }
      if (page.blocks.isEmpty) {
        add('$path.blocks', 'A page must contain at least one content block.');
      }

      checkOptionalString(
        pageJson,
        'subtitle',
        '$path.subtitle',
        nullable: true,
      );
      final estimatedSeconds = pageJson['estimatedSeconds'];
      if (estimatedSeconds != null &&
          (estimatedSeconds is! int || estimatedSeconds < 10)) {
        add('$path.estimatedSeconds', 'Must be an integer of at least 10 or null.');
      }

      for (var j = 0; j < page.blocks.length; j++) {
        final block = page.blocks[j];
        final blockPath = '$path.blocks[$j]';
        final blockJson = block.rawJson;

        if (!_blockTypes.contains(block.type)) {
          add('$blockPath.type', 'Unknown block type "${block.type}".');
        }

        final blockId = blockJson['id'];
        if (blockId != null) {
          if (blockId is! String || blockId.trim().isEmpty) {
            add('$blockPath.id', 'Block ID must be a non-empty string.');
          } else if (!blockIds.add(blockId)) {
            add('$blockPath.id', 'Duplicate block ID "$blockId".');
          }
        }

        for (final key in ['text', 'title', 'label', 'assetId', 'alt', 'question']) {
          checkOptionalString(blockJson, key, '$blockPath.$key');
        }
        final tone = blockJson['tone'];
        if (tone != null &&
            !{'info', 'pearl', 'warning', 'danger', 'success'}.contains(tone)) {
          add('$blockPath.tone', 'Unsupported block tone "$tone".');
        }
        for (final key in ['items', 'columns', 'rows']) {
          final value = blockJson[key];
          if (value != null && value is! List) {
            add('$blockPath.$key', 'Must be an array.');
          }
        }
      }
    }

    final sourceIds = <String>{};
    for (var i = 0; i < package.sources.length; i++) {
      final source = package.sources[i];
      final path = 'sources[$i]';
      final json = source.rawJson;

      if (source.id.trim().isEmpty) {
        add('$path.id', 'Source ID must not be empty.');
      } else if (!sourceIds.add(source.id)) {
        add('$path.id', 'Duplicate source ID "${source.id}".');
      }

      for (final key in ['title', 'organization']) {
        final value = json[key];
        if (value is! String || value.trim().isEmpty) {
          add('$path.$key', 'Must be a non-empty string.');
        }
      }

      if (!{'guideline', 'textbook', 'primary_study', 'review', 'local_protocol', 'other'}
          .contains(json['sourceType'])) {
        add('$path.sourceType', 'Unsupported source type.');
      }
      if (!{'placeholder', 'verified', 'needs_review'}.contains(json['status'])) {
        add('$path.status', 'Unsupported source status.');
      }

      final year = json['year'];
      if (year != null && year is! int) {
        add('$path.year', 'Must be an integer or null.');
      }
      for (final key in ['edition', 'url', 'accessedAt', 'notes']) {
        checkOptionalString(json, key, '$path.$key', nullable: true);
      }
    }

    for (var i = 0; i < package.pages.length; i++) {
      final sourceIdsValue = package.pages[i].rawJson['sourceIds'];
      if (sourceIdsValue == null) continue;

      final path = 'pages[$i].sourceIds';
      if (sourceIdsValue is! List) {
        add(path, 'Source references must be a JSON array.');
        continue;
      }

      final seen = <String>{};
      for (var j = 0; j < sourceIdsValue.length; j++) {
        final value = sourceIdsValue[j];

        if (value is! String || value.trim().isEmpty) {
          add('$path[$j]', 'Source ID must be a non-empty string.');
          continue;
        }
        if (!seen.add(value)) {
          add('$path[$j]', 'Source "$value" is listed more than once.');
        }
        if (!sourceIds.contains(value)) {
          add('$path[$j]', 'Source "$value" does not exist in this package.');
        }
      }
    }

    return TopicPackageValidationResult(List.unmodifiable(issues));
  }
}
