import 'package:isar/isar.dart';

import '../../../../core/sync/sync_metadata.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/taxonomy_node.dart';
import '../models/note_mapper.dart';
import '../models/note_model.dart';
import '../models/taxonomy_node_mapper.dart';
import '../models/taxonomy_node_model.dart';

class SingleTopicJsonImportException implements Exception {
  const SingleTopicJsonImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SingleTopicJsonImportResult {
  const SingleTopicJsonImportResult({
    required this.parentTitle,
    required this.childTopicCount,
    required this.noteCount,
  });

  final String parentTitle;
  final int childTopicCount;
  final int noteCount;
}

/// Imports one hierarchical study-document JSON into a selected taxonomy node.
///
/// The JSON document title becomes a new parent topic. Its definition becomes
/// an Introduction child, and each item in `topics` becomes another child.
/// Each child receives one detailed-notes record. The entire write is atomic.
class SingleTopicJsonImporter {
  SingleTopicJsonImporter({
    required Isar isar,
    required String Function() generateUuid,
    required SyncMetadata Function() createSyncMetadata,
    required DateTime Function() now,
  })  : _isar = isar,
        _generateUuid = generateUuid,
        _createSyncMetadata = createSyncMetadata,
        _now = now;

  final Isar _isar;
  final String Function() _generateUuid;
  final SyncMetadata Function() _createSyncMetadata;
  final DateTime Function() _now;

  Future<SingleTopicJsonImportResult> importDocument({
    required TaxonomyNode destination,
    required Map<String, dynamic> document,
  }) async {
    if (destination.nodeType != NodeType.system &&
        destination.nodeType != NodeType.topic) {
      throw const SingleTopicJsonImportException(
        'Choose a system or topic as the destination.',
      );
    }

    final prepared = _prepare(document);
    final timestamp = _now();

    return _isar.writeTxn(() async {
      final existingNodes = await _isar.taxonomyNodeModels.where().findAll();
      final existingNotes = await _isar.noteModels.where().findAll();

      final siblings = existingNodes
          .where((node) => node.parentUuid == destination.uuid)
          .toList();

      final requestedSlug = _slug(prepared.title);
      if (siblings.any((node) => _slug(node.title) == requestedSlug)) {
        throw SingleTopicJsonImportException(
          'A topic named "${prepared.title}" already exists here. '
          'Rename the JSON document title or choose another destination.',
        );
      }

      final parentUuid = _generateUuid();
      final parentPath = '${destination.path}/$parentUuid';
      final parentDepth = destination.depth + 1;
      final parentNode = TaxonomyNode(
        uuid: parentUuid,
        parentUuid: destination.uuid,
        path: parentPath,
        depth: parentDepth,
        nodeType: NodeType.topic,
        title: prepared.title,
        slug: requestedSlug,
        sortOrder: siblings.length,
        noteCount: prepared.directNote == null ? 0 : 1,
        isUserCreated: true,
        createdAt: timestamp,
        updatedAt: timestamp,
        sync: _createSyncMetadata(),
      );

      final childNodes = <TaxonomyNode>[];
      final notes = <Note>[];
      final usedSlugs = <String>{};

      for (var i = 0; i < prepared.children.length; i++) {
        final child = prepared.children[i];
        final childSlug = _slug(child.title);

        if (childSlug.isEmpty || !usedSlugs.add(childSlug)) {
          throw SingleTopicJsonImportException(
            'The JSON contains an empty or duplicate child topic title: '
            '"${child.title}".',
          );
        }

        final childUuid = _generateUuid();
        childNodes.add(
          TaxonomyNode(
            uuid: childUuid,
            parentUuid: parentUuid,
            path: '$parentPath/$childUuid',
            depth: parentDepth + 1,
            nodeType: NodeType.topic,
            title: child.title,
            slug: childSlug,
            sortOrder: i,
            noteCount: 1,
            isUserCreated: true,
            createdAt: timestamp,
            updatedAt: timestamp,
            sync: _createSyncMetadata(),
          ),
        );

        notes.add(
          Note(
            uuid: _generateUuid(),
            topicUuid: childUuid,
            mode: Mode.detailedNotes,
            title: child.noteTitle,
            bodyMarkdown: child.markdown,
            plainTextExtract: child.plainText,
            tags: <String>[
              if (prepared.rotation != null) prepared.rotation!,
            ],
            citationOrder: const <String>[],
            isPinned: false,
            createdAt: timestamp,
            updatedAt: timestamp,
            sync: _createSyncMetadata(),
          ),
        );
      }

      final directNote = prepared.directNote;
      if (directNote != null) {
        notes.add(
          Note(
            uuid: _generateUuid(),
            topicUuid: parentUuid,
            mode: Mode.detailedNotes,
            title: directNote.noteTitle,
            bodyMarkdown: directNote.markdown,
            plainTextExtract: directNote.plainText,
            tags: <String>[
              if (prepared.rotation != null) prepared.rotation!,
            ],
            citationOrder: const <String>[],
            isPinned: false,
            createdAt: timestamp,
            updatedAt: timestamp,
            sync: _createSyncMetadata(),
          ),
        );
      }

      final generatedUuids = <String>{
        parentUuid,
        ...childNodes.map((node) => node.uuid),
        ...notes.map((note) => note.uuid),
      };
      if (generatedUuids.length != 1 + childNodes.length + notes.length ||
          existingNodes.any((node) => generatedUuids.contains(node.uuid)) ||
          existingNotes.any((note) => generatedUuids.contains(note.uuid))) {
        throw const SingleTopicJsonImportException(
          'A generated identifier conflicted with existing data. '
          'Nothing was imported; please try again.',
        );
      }

      await _isar.taxonomyNodeModels.putAll(<TaxonomyNodeModel>[
        TaxonomyNodeMapper.toModel(parentNode),
        ...childNodes.map(TaxonomyNodeMapper.toModel),
      ]);
      await _isar.noteModels.putAll(
        notes.map(NoteMapper.toModel).toList(),
      );

      return SingleTopicJsonImportResult(
        parentTitle: prepared.title,
        childTopicCount: childNodes.length,
        noteCount: notes.length,
      );
    });
  }

  _PreparedDocument _prepare(Map<String, dynamic> document) {
    final title = _requiredString(document['title'], 'title');
    final rotation = _optionalString(document['rotation']);
    final source = _optionalString(document['source']);
    final definitionValue = document['definition'];

    String? definitionText;
    List<dynamic> definitionHighlights = const <dynamic>[];
    if (definitionValue != null) {
      if (definitionValue is! Map) {
        throw const SingleTopicJsonImportException(
          '"definition" must be an object.',
        );
      }
      final definition = Map<String, dynamic>.from(definitionValue);
      definitionText = _requiredString(definition['text'], 'definition.text');
      definitionHighlights = _listOrEmpty(
        definition['highlights'],
        'definition.highlights',
      );
    }

    final sourceTopics = document['topics'];
    if (sourceTopics is! List || sourceTopics.isEmpty) {
      final rawSections = document['sections'];
      if (rawSections is List && rawSections.isNotEmpty) {
        return _prepareStandalone(
          title: title,
          rotation: rotation,
          source: source,
          document: document,
          sections: rawSections,
        );
      }
      throw const SingleTopicJsonImportException(
        'The JSON must contain a non-empty "topics" array or "sections" array.',
      );
    }

    final children = <_PreparedChild>[];
    final introParts = <String>[];
    if (source != null) introParts.add('**Source:** $source');
    if (rotation != null) introParts.add('**Rotation:** $rotation');
    if (definitionText != null) {
      introParts
        ..add('## Definition')
        ..add(_annotatedText(definitionText, definitionHighlights));
    }
    _appendLegends(introParts, document);

    children.add(
      _PreparedChild(
        title: 'Introduction',
        noteTitle: '$title — Introduction',
        markdown: _render(introParts),
      ),
    );

    for (var topicIndex = 0; topicIndex < sourceTopics.length; topicIndex++) {
      final rawTopic = sourceTopics[topicIndex];
      if (rawTopic is! Map) {
        throw SingleTopicJsonImportException(
          'topics[$topicIndex] must be an object.',
        );
      }
      final topic = Map<String, dynamic>.from(rawTopic);
      final topicTitle = _requiredString(
        topic['title'],
        'topics[$topicIndex].title',
      );
      final sections = topic['sections'];
      if (sections is! List || sections.isEmpty) {
        throw SingleTopicJsonImportException(
          'The "$topicTitle" topic must contain a non-empty sections array.',
        );
      }

      final parts = <String>[];
      if (source != null) parts.add('**Source:** $source');
      if (rotation != null) parts.add('**Rotation:** $rotation');

      for (var sectionIndex = 0;
          sectionIndex < sections.length;
          sectionIndex++) {
        final rawSection = sections[sectionIndex];
        if (rawSection is! Map) {
          throw SingleTopicJsonImportException(
            '"$topicTitle": sections[$sectionIndex] must be an object.',
          );
        }
        final section = Map<String, dynamic>.from(rawSection);
        final heading = _requiredString(
          section['heading'],
          '$topicTitle.sections[$sectionIndex].heading',
        );
        final points = section['points'];
        if (points is! List || points.isEmpty) {
          throw SingleTopicJsonImportException(
            'Section "$heading" must contain a non-empty points array.',
          );
        }

        parts.add('## $heading');
        for (var pointIndex = 0; pointIndex < points.length; pointIndex++) {
          final rawPoint = points[pointIndex];
          if (rawPoint is! Map) {
            throw SingleTopicJsonImportException(
              '"$heading": points[$pointIndex] must be an object.',
            );
          }
          final point = Map<String, dynamic>.from(rawPoint);
          final text = _requiredString(
            point['text'],
            '$heading.points[$pointIndex].text',
          );
          final annotations = <String>[];

          final highlights = _listOrEmpty(
            point['highlights'],
            'highlights',
          );
          for (final item in highlights) {
            if (item is! Map) {
              throw const SingleTopicJsonImportException(
                'Each highlight must be an object.',
              );
            }
            final highlight = Map<String, dynamic>.from(item);
            final match = _optionalString(highlight['match']);
            final color = _optionalString(highlight['color']);
            if (match != null || color != null) {
              annotations.add(
                'Highlight${color == null ? '' : ' ($color)'}'
                '${match == null ? '' : ': "$match"'}',
              );
            }
          }

          final marker = _optionalString(point['marker']);
          if (marker != null) annotations.add('Marker: $marker');

          final flagValue = point['flag'];
          if (flagValue != null) {
            if (flagValue is! Map) {
              throw const SingleTopicJsonImportException(
                'A point "flag" must be an object.',
              );
            }
            final flag = Map<String, dynamic>.from(flagValue);
            final status = _optionalString(flag['status']);
            final note = _optionalString(flag['note']);
            if (status != null) annotations.add('Flag: $status');
            if (note != null) annotations.add('Flag note: $note');
          }

          parts.add(
            '- $text${annotations.isEmpty ? '' : '\n  - ${annotations.join('\n  - ')}'}',
          );
        }
      }

      _appendLegends(parts, document);
      children.add(
        _PreparedChild(
          title: topicTitle,
          noteTitle: topicTitle,
          markdown: _render(parts),
        ),
      );
    }

    final childSlugs = children.map((child) => _slug(child.title)).toList();
    if (childSlugs.any((slug) => slug.isEmpty) ||
        childSlugs.toSet().length != childSlugs.length) {
      throw const SingleTopicJsonImportException(
        'The JSON produces duplicate or empty child topic titles. '
        'Rename the repeated topics before importing.',
      );
    }

    return _PreparedDocument(
      title: title,
      rotation: rotation,
      children: children,
    );
  }

  _PreparedDocument _prepareStandalone({
    required String title,
    required String? rotation,
    required String? source,
    required Map<String, dynamic> document,
    required List<dynamic> sections,
  }) {
    final metaValue = document['meta'];
    if (metaValue != null && metaValue is! Map) {
      throw const SingleTopicJsonImportException(
        '"meta" must be an object.',
      );
    }
    final meta = metaValue is Map
        ? Map<String, dynamic>.from(metaValue)
        : <String, dynamic>{};

    final effectiveSource = source ?? _optionalString(meta['source']);
    final parts = <String>[];
    if (effectiveSource != null) {
      parts.add('**Source:** $effectiveSource');
    }
    final metaTopic = _optionalString(meta['topic']);
    if (metaTopic != null) parts.add('**Topic:** $metaTopic');
    if (rotation != null) parts.add('**Rotation:** $rotation');

    String renderPoint(dynamic rawPoint, String field, int depth) {
      if (rawPoint is! Map) {
        throw SingleTopicJsonImportException('$field must be an object.');
      }

      final point = Map<String, dynamic>.from(rawPoint);
      final text = _requiredString(
        point['text'] ?? point['html'],
        '$field.text',
      );
      final rawSpans = _listOrEmpty(point['spans'], '$field.spans');

      var renderedText = text;
      if (rawSpans.isNotEmpty) {
        final reconstructed = StringBuffer();
        final rendered = StringBuffer();

        for (var i = 0; i < rawSpans.length; i++) {
          final rawSpan = rawSpans[i];
          if (rawSpan is! Map) {
            throw SingleTopicJsonImportException(
              '$field.spans[$i] must be an object.',
            );
          }
          final span = Map<String, dynamic>.from(rawSpan);
          final spanText = span['text'];
          if (spanText is! String || spanText.isEmpty) {
            throw SingleTopicJsonImportException(
              '"$field.spans[$i].text" must be a non-empty string.',
            );
          }
          reconstructed.write(spanText);

          final highlight = _optionalString(span['highlight']);
          final color = _optionalString(span['highlightColor']);

          if (highlight != null && color != null) {
            if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(color)) {
              throw SingleTopicJsonImportException(
                '$field.spans[$i].highlightColor must be a six-digit hex colour.',
              );
            }
            rendered
              ..write('[[CC_HL:$color]]')
              ..write(spanText)
              ..write('[[/CC_HL]]');
          } else {
            rendered.write(spanText);
          }
        }

        if (reconstructed.toString() != text) {
          throw SingleTopicJsonImportException(
            '$field.spans do not reconstruct the original text.',
          );
        }
        renderedText = rendered.toString();
      }

      final important = point['important'] == true;
      final indent = '  ' * depth;
      final lines = <String>[
        '$indent- ${important ? "**Important:** " : ""}$renderedText',
      ];

      final rawChildren = _listOrEmpty(
        point['children'],
        '$field.children',
      );
      for (var i = 0; i < rawChildren.length; i++) {
        lines.add(renderPoint(
          rawChildren[i],
          '$field.children[$i]',
          depth + 1,
        ));
      }

      return lines.join('\n');
    }

    for (var sectionIndex = 0;
        sectionIndex < sections.length;
        sectionIndex++) {
      final rawSection = sections[sectionIndex];
      if (rawSection is! Map) {
        throw SingleTopicJsonImportException(
          'sections[$sectionIndex] must be an object.',
        );
      }

      final section = Map<String, dynamic>.from(rawSection);
      final heading = _requiredString(
        section['title'],
        'sections[$sectionIndex].title',
      );
      final points = section['points'];
      if (points is! List || points.isEmpty) {
        throw SingleTopicJsonImportException(
          'Section "$heading" must contain a non-empty points array.',
        );
      }

      parts.add('## $heading');
      for (var pointIndex = 0; pointIndex < points.length; pointIndex++) {
        parts.add(renderPoint(
          points[pointIndex],
          'sections[$sectionIndex].points[$pointIndex]',
          0,
        ));
      }

      final sectionNote = _optionalString(section['note']);
      if (sectionNote != null) {
        parts.add(
          '> **Note:** ${sectionNote.replaceAll('\n', '\n> ')}',
        );
      }
    }

    _appendLegends(
      parts,
      <String, dynamic>{
        ...document,
        'highlightLegend':
            meta['highlightLegend'] ?? document['highlightLegend'],
      },
    );

    return _PreparedDocument(
      title: title,
      rotation: rotation,
      children: const <_PreparedChild>[],
      directNote: _PreparedChild(
        title: title,
        noteTitle: title,
        markdown: _render(parts),
      ),
    );
  }

  String _annotatedText(String text, List<dynamic> highlights) {
    final lines = <String>[text];
    for (final item in highlights) {
      if (item is! Map) {
        throw const SingleTopicJsonImportException(
          'Each definition highlight must be an object.',
        );
      }
      final highlight = Map<String, dynamic>.from(item);
      final match = _optionalString(highlight['match']);
      final color = _optionalString(highlight['color']);
      if (match != null || color != null) {
        lines.add(
          '- Highlight${color == null ? '' : ' ($color)'}'
          '${match == null ? '' : ': "$match"'}',
        );
      }
    }
    return lines.join('\n');
  }

  void _appendLegends(List<String> parts, Map<String, dynamic> document) {
    final legends = <String, dynamic>{
      'Highlight legend': document['highlightLegend'],
      'Marker legend': document['markerLegend'],
      'Flag legend': document['flagLegend'],
    };
    final lines = <String>[];
    for (final entry in legends.entries) {
      final value = entry.value;
      if (value is! Map || value.isEmpty) continue;
      lines.add('**${entry.key}**');
      for (final item in value.entries) {
        lines.add('- ${item.key}: ${item.value}');
      }
    }
    if (lines.isNotEmpty) {
      parts
        ..add('## Annotation key')
        ..addAll(lines);
    }
  }

  List<dynamic> _listOrEmpty(dynamic value, String field) {
    if (value == null) return const <dynamic>[];
    if (value is! List) {
      throw SingleTopicJsonImportException('"$field" must be an array.');
    }
    return value;
  }

  String _requiredString(dynamic value, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw SingleTopicJsonImportException(
        '"$field" must be a non-empty string.',
      );
    }
    return value.trim();
  }

  String? _optionalString(dynamic value) {
    if (value == null) return null;
    if (value is! String) {
      throw const SingleTopicJsonImportException(
        'An optional text field must be a string.',
      );
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _slug(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  String _render(List<String> parts) =>
      parts.where((part) => part.trim().isNotEmpty).join('\n\n');
}

class _PreparedDocument {
  const _PreparedDocument({
    required this.title,
    required this.rotation,
    required this.children,
    this.directNote,
  });

  final String title;
  final String? rotation;
  final List<_PreparedChild> children;
  final _PreparedChild? directNote;
}

class _PreparedChild {
  const _PreparedChild({
    required this.title,
    required this.noteTitle,
    required this.markdown,
  });

  final String title;
  final String noteTitle;
  final String markdown;

  String get plainText => markdown
      .replaceAll(RegExp(r'[#*_`]'), '')
      .replaceAll(RegExp(r'\n+'), '\n')
      .trim();
}
