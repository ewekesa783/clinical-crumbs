/// Typed representation of a schema-driven Clinical Crumbs topic package.
///
/// This model parses package structure only. Clinical accuracy and publication
/// approval must be assessed separately.
class TopicPackage {
  const TopicPackage({
    required this.schemaVersion,
    required this.topic,
    required this.pages,
    required this.sources,
    required this.rawJson,
  });

  final String schemaVersion;
  final TopicMetadata topic;
  final List<TopicPage> pages;
  final List<TopicSource> sources;

  /// Original decoded package, preserving fields not yet modelled explicitly.
  final Map<String, dynamic> rawJson;

  factory TopicPackage.fromJson(Map<String, dynamic> json) {
    final topicJson = _requiredMap(json, 'topic');
    final pagesJson = _requiredList(json, 'pages');
    final sourcesJson = _requiredList(json, 'sources');

    return TopicPackage(
      schemaVersion: _requiredString(json, 'schemaVersion'),
      topic: TopicMetadata.fromJson(topicJson),
      pages: List.unmodifiable(
        pagesJson.map(
          (value) => TopicPage.fromJson(_asMap(value, 'pages[]')),
        ),
      ),
      sources: List.unmodifiable(
        sourcesJson.map(
          (value) => TopicSource.fromJson(_asMap(value, 'sources[]')),
        ),
      ),
      rawJson: _deepCopyMap(json),
    );
  }

  Map<String, dynamic> toJson() => _deepCopyMap(rawJson);
}

class TopicMetadata {
  const TopicMetadata({
    required this.id,
    required this.title,
    required this.specialty,
    required this.contentVersion,
    required this.reviewStatus,
    required this.rawJson,
  });

  final String id;
  final String title;
  final String specialty;
  final int contentVersion;
  final String reviewStatus;
  final Map<String, dynamic> rawJson;

  factory TopicMetadata.fromJson(Map<String, dynamic> json) {
    return TopicMetadata(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      specialty: _requiredString(json, 'specialty'),
      contentVersion: _requiredInt(json, 'contentVersion'),
      reviewStatus: _requiredString(json, 'reviewStatus'),
      rawJson: _deepCopyMap(json),
    );
  }

  Map<String, dynamic> toJson() => _deepCopyMap(rawJson);
}

class TopicPage {
  const TopicPage({
    required this.id,
    required this.type,
    required this.title,
    required this.blocks,
    required this.rawJson,
  });

  final String id;
  final String type;
  final String title;
  final List<TopicContentBlock> blocks;
  final Map<String, dynamic> rawJson;

  factory TopicPage.fromJson(Map<String, dynamic> json) {
    final blocksJson = _requiredList(json, 'blocks');

    return TopicPage(
      id: _requiredString(json, 'id'),
      type: _requiredString(json, 'type'),
      title: _requiredString(json, 'title'),
      blocks: List.unmodifiable(
        blocksJson.map(
          (value) => TopicContentBlock.fromJson(
            _asMap(value, 'blocks[]'),
          ),
        ),
      ),
      rawJson: _deepCopyMap(json),
    );
  }

  Map<String, dynamic> toJson() => _deepCopyMap(rawJson);
}

class TopicContentBlock {
  const TopicContentBlock({
    required this.type,
    required this.rawJson,
  });

  final String type;

  /// Retains type-specific fields for renderers and future schema evolution.
  final Map<String, dynamic> rawJson;

  factory TopicContentBlock.fromJson(Map<String, dynamic> json) {
    return TopicContentBlock(
      type: _requiredString(json, 'type'),
      rawJson: _deepCopyMap(json),
    );
  }

  Map<String, dynamic> toJson() => _deepCopyMap(rawJson);
}

class TopicSource {
  const TopicSource({
    required this.id,
    required this.rawJson,
  });

  final String id;

  /// Source metadata is retained without assuming every source type has
  /// identical fields.
  final Map<String, dynamic> rawJson;

  factory TopicSource.fromJson(Map<String, dynamic> json) {
    return TopicSource(
      id: _requiredString(json, 'id'),
      rawJson: _deepCopyMap(json),
    );
  }

  Map<String, dynamic> toJson() => _deepCopyMap(rawJson);
}

Map<String, dynamic> _requiredMap(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value is! Map) {
    throw FormatException('"$key" must be a JSON object.');
  }
  return _asMap(value, key);
}

List<dynamic> _requiredList(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('"$key" must be a JSON array.');
  }
  return value;
}

Map<String, dynamic> _asMap(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be a JSON object.');
  }

  try {
    return Map<String, dynamic>.from(value);
  } on TypeError {
    throw FormatException('$path must have string keys.');
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('"$key" must be a string.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('"$key" must be an integer.');
  }
  return value;
}

Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) {
  return source.map((key, value) => MapEntry(key, _deepCopyValue(value)));
}

dynamic _deepCopyValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key,
        _deepCopyValue(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value.map(_deepCopyValue).toList();
  }
  return value;
}
