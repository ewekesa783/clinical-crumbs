import 'curriculum_pack.dart';

/// A single actionable curriculum-pack validation issue.
class CurriculumPackValidationIssue {
  const CurriculumPackValidationIssue({
    required this.path,
    required this.message,
  });

  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}

/// Validation report for a curriculum pack.
class CurriculumPackValidationResult {
  const CurriculumPackValidationResult(this.issues);

  final List<CurriculumPackValidationIssue> issues;

  bool get isValid => issues.isEmpty;
}

/// Validates structural integrity and cross-references in a curriculum pack.
///
/// This validator checks the pack's data structure only. It does not assess
/// the accuracy or quality of authored medical content.
class CurriculumPackValidator {
  const CurriculumPackValidator();

  static const _nodeTypes = {'subject', 'system', 'topic', 'custom'};
  static const _noteModes = {
    'detailedNotes',
    'visualLearning',
    'quickReview',
  };
  static const _sourceTypes = {
    'textbook',
    'journalArticle',
    'guideline',
    'lectureSlide',
    'other',
  };

  CurriculumPackValidationResult validate(CurriculumPack pack) {
    final issues = <CurriculumPackValidationIssue>[];

    void add(String path, String message) {
      issues.add(CurriculumPackValidationIssue(
        path: path,
        message: message,
      ));
    }

    final manifest = pack.manifest;

    if (manifest.formatVersion != currentCurriculumPackFormatVersion) {
      add(
        'manifest.formatVersion',
        'Unsupported format version ${manifest.formatVersion}; '
            'supported version is $currentCurriculumPackFormatVersion.',
      );
    }
    if (manifest.packUuid.trim().isEmpty) {
      add('manifest.packUuid', 'Pack UUID must not be empty.');
    }
    if (manifest.version < 1) {
      add('manifest.version', 'Pack version must be at least 1.');
    }
    if (manifest.title.trim().isEmpty) {
      add('manifest.title', 'Pack title must not be empty.');
    }

    final nodeById = <String, CurriculumPackTaxonomyNode>{};
    for (var i = 0; i < pack.taxonomyNodes.length; i++) {
      final node = pack.taxonomyNodes[i];
      final path = 'taxonomyNodes[$i]';

      if (node.uuid.trim().isEmpty) {
        add('$path.uuid', 'Node UUID must not be empty.');
      } else if (nodeById.containsKey(node.uuid)) {
        add('$path.uuid', 'Duplicate taxonomy UUID "${node.uuid}".');
      } else {
        nodeById[node.uuid] = node;
      }

      if (!_nodeTypes.contains(node.nodeType)) {
        add('$path.nodeType', 'Unknown node type "${node.nodeType}".');
      }
      if (node.title.trim().isEmpty) {
        add('$path.title', 'Node title must not be empty.');
      }
      if (node.slug.trim().isEmpty) {
        add('$path.slug', 'Node slug must not be empty.');
      }
      if (node.sortOrder < 0) {
        add('$path.sortOrder', 'Sort order must not be negative.');
      }
    }

    for (var i = 0; i < pack.taxonomyNodes.length; i++) {
      final node = pack.taxonomyNodes[i];
      final parentUuid = node.parentUuid;

      if (parentUuid != null && !nodeById.containsKey(parentUuid)) {
        add(
          'taxonomyNodes[$i].parentUuid',
          'Parent "$parentUuid" does not exist in this pack.',
        );
      }
    }

    // Detect cycles by following each node's parent chain.
    for (var i = 0; i < pack.taxonomyNodes.length; i++) {
      final start = pack.taxonomyNodes[i];
      final visited = <String>{};
      var current = start;

      while (true) {
        if (!visited.add(current.uuid)) {
          add(
            'taxonomyNodes[$i].parentUuid',
            'Taxonomy hierarchy contains a cycle involving "${current.uuid}".',
          );
          break;
        }

        final parentUuid = current.parentUuid;
        if (parentUuid == null) break;

        final parent = nodeById[parentUuid];
        if (parent == null) break;
        current = parent;
      }
    }

    final citationById = <String, CurriculumPackCitation>{};
    for (var i = 0; i < pack.citations.length; i++) {
      final citation = pack.citations[i];
      final path = 'citations[$i]';

      if (citation.uuid.trim().isEmpty) {
        add('$path.uuid', 'Citation UUID must not be empty.');
      } else if (citationById.containsKey(citation.uuid)) {
        add('$path.uuid', 'Duplicate citation UUID "${citation.uuid}".');
      } else {
        citationById[citation.uuid] = citation;
      }

      if (!_sourceTypes.contains(citation.sourceType)) {
        add(
          '$path.sourceType',
          'Unknown citation source type "${citation.sourceType}".',
        );
      }
      if (citation.title.trim().isEmpty) {
        add('$path.title', 'Citation title must not be empty.');
      }
      if (citation.publicationYear != null &&
          (citation.publicationYear! < 1000 ||
              citation.publicationYear! > 9999)) {
        add(
          '$path.publicationYear',
          'Publication year must be between 1000 and 9999.',
        );
      }
      if (citation.url != null && !_isValidHttpUrl(citation.url!)) {
        add('$path.url', 'Citation URL must be a valid HTTP or HTTPS URL.');
      }
    }

    final noteIds = <String>{};
    for (var i = 0; i < pack.notes.length; i++) {
      final note = pack.notes[i];
      final path = 'notes[$i]';

      if (note.uuid.trim().isEmpty) {
        add('$path.uuid', 'Note UUID must not be empty.');
      } else if (!noteIds.add(note.uuid)) {
        add('$path.uuid', 'Duplicate note UUID "${note.uuid}".');
      }

      if (!nodeById.containsKey(note.topicUuid)) {
        add(
          '$path.topicUuid',
          'Taxonomy node "${note.topicUuid}" does not exist in this pack.',
        );
      }
      if (!_noteModes.contains(note.mode)) {
        add('$path.mode', 'Unknown note mode "${note.mode}".');
      }
      if (note.title.trim().isEmpty) {
        add('$path.title', 'Note title must not be empty.');
      }
      if (note.bodyMarkdown.trim().isEmpty) {
        add('$path.bodyMarkdown', 'Note body must not be empty.');
      }

      final seenCitationIds = <String>{};
      for (var j = 0; j < note.citationOrder.length; j++) {
        final citationUuid = note.citationOrder[j];

        if (!seenCitationIds.add(citationUuid)) {
          add(
            '$path.citationOrder[$j]',
            'Citation "$citationUuid" is listed more than once.',
          );
        }
        if (!citationById.containsKey(citationUuid)) {
          add(
            '$path.citationOrder[$j]',
            'Citation "$citationUuid" does not exist in this pack.',
          );
        }
      }

      final seenTags = <String>{};
      for (var j = 0; j < note.tags.length; j++) {
        final tag = note.tags[j];
        if (tag.trim().isEmpty) {
          add('$path.tags[$j]', 'Tag must not be empty.');
        } else if (!seenTags.add(tag)) {
          add('$path.tags[$j]', 'Duplicate tag "$tag".');
        }
      }
    }

    return CurriculumPackValidationResult(
      List<CurriculumPackValidationIssue>.unmodifiable(issues),
    );
  }

  bool _isValidHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
