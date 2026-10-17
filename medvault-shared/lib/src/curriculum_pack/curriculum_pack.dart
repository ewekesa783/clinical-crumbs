/// Versioned, portable data contract for authored MedVault curriculum packs.
///
/// This package describes content only. Local database IDs, sync metadata,
/// bookmarks, and reading history belong to the consuming application.
library;

const int currentCurriculumPackFormatVersion = 1;

/// Metadata identifying a curriculum pack and its format version.
class CurriculumPackManifest {
  const CurriculumPackManifest({
    required this.formatVersion,
    required this.packUuid,
    required this.version,
    required this.title,
    this.description,
  });

  final int formatVersion;
  final String packUuid;
  final int version;
  final String title;
  final String? description;

  Map<String, dynamic> toJson() => {
        'formatVersion': formatVersion,
        'packUuid': packUuid,
        'version': version,
        'title': title,
        if (description != null) 'description': description,
      };

  factory CurriculumPackManifest.fromJson(Map<String, dynamic> json) {
    return CurriculumPackManifest(
      formatVersion: json['formatVersion'] as int,
      packUuid: json['packUuid'] as String,
      version: json['version'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
    );
  }
}

/// A node in the authored subject/system/topic hierarchy.
class CurriculumPackTaxonomyNode {
  const CurriculumPackTaxonomyNode({
    required this.uuid,
    this.parentUuid,
    required this.nodeType,
    required this.title,
    required this.slug,
    this.shortDescription,
    this.iconKey,
    required this.sortOrder,
  });

  final String uuid;
  final String? parentUuid;
  final String nodeType;
  final String title;
  final String slug;
  final String? shortDescription;
  final String? iconKey;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        if (parentUuid != null) 'parentUuid': parentUuid,
        'nodeType': nodeType,
        'title': title,
        'slug': slug,
        if (shortDescription != null) 'shortDescription': shortDescription,
        if (iconKey != null) 'iconKey': iconKey,
        'sortOrder': sortOrder,
      };

  factory CurriculumPackTaxonomyNode.fromJson(Map<String, dynamic> json) {
    return CurriculumPackTaxonomyNode(
      uuid: json['uuid'] as String,
      parentUuid: json['parentUuid'] as String?,
      nodeType: json['nodeType'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      shortDescription: json['shortDescription'] as String?,
      iconKey: json['iconKey'] as String?,
      sortOrder: json['sortOrder'] as int,
    );
  }
}

/// An authored note belonging to a taxonomy node.
class CurriculumPackNote {
  const CurriculumPackNote({
    required this.uuid,
    required this.topicUuid,
    required this.mode,
    required this.title,
    required this.bodyMarkdown,
    required this.tags,
    required this.citationOrder,
  });

  final String uuid;
  final String topicUuid;
  final String mode;
  final String title;
  final String bodyMarkdown;
  final List<String> tags;

  /// Citation UUIDs in the order in which they should be displayed.
  final List<String> citationOrder;

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'topicUuid': topicUuid,
        'mode': mode,
        'title': title,
        'bodyMarkdown': bodyMarkdown,
        'tags': List<String>.of(tags),
        'citationOrder': List<String>.of(citationOrder),
      };

  factory CurriculumPackNote.fromJson(Map<String, dynamic> json) {
    return CurriculumPackNote(
      uuid: json['uuid'] as String,
      topicUuid: json['topicUuid'] as String,
      mode: json['mode'] as String,
      title: json['title'] as String,
      bodyMarkdown: json['bodyMarkdown'] as String,
      tags: List<String>.from(json['tags'] as List),
      citationOrder: List<String>.from(json['citationOrder'] as List),
    );
  }
}

/// Source metadata referenced by one or more authored notes.
class CurriculumPackCitation {
  const CurriculumPackCitation({
    required this.uuid,
    required this.sourceType,
    required this.title,
    this.authors,
    this.publicationYear,
    this.pageReference,
    this.url,
  });

  final String uuid;
  final String sourceType;
  final String title;
  final String? authors;
  final int? publicationYear;
  final String? pageReference;
  final String? url;

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'sourceType': sourceType,
        'title': title,
        if (authors != null) 'authors': authors,
        if (publicationYear != null) 'publicationYear': publicationYear,
        if (pageReference != null) 'pageReference': pageReference,
        if (url != null) 'url': url,
      };

  factory CurriculumPackCitation.fromJson(Map<String, dynamic> json) {
    return CurriculumPackCitation(
      uuid: json['uuid'] as String,
      sourceType: json['sourceType'] as String,
      title: json['title'] as String,
      authors: json['authors'] as String?,
      publicationYear: json['publicationYear'] as int?,
      pageReference: json['pageReference'] as String?,
      url: json['url'] as String?,
    );
  }
}

/// Complete portable curriculum pack.
///
/// The lists preserve authored order. Cross-reference and integrity checks
/// are performed by the validation layer before a pack is imported.
class CurriculumPack {
  const CurriculumPack({
    required this.manifest,
    required this.taxonomyNodes,
    required this.notes,
    required this.citations,
  });

  final CurriculumPackManifest manifest;
  final List<CurriculumPackTaxonomyNode> taxonomyNodes;
  final List<CurriculumPackNote> notes;
  final List<CurriculumPackCitation> citations;

  Map<String, dynamic> toJson() => {
        'manifest': manifest.toJson(),
        'taxonomyNodes': taxonomyNodes.map((node) => node.toJson()).toList(),
        'notes': notes.map((note) => note.toJson()).toList(),
        'citations': citations.map((citation) => citation.toJson()).toList(),
      };

  factory CurriculumPack.fromJson(Map<String, dynamic> json) {
    return CurriculumPack(
      manifest: CurriculumPackManifest.fromJson(
        Map<String, dynamic>.from(json['manifest'] as Map),
      ),
      taxonomyNodes: (json['taxonomyNodes'] as List)
          .map(
            (item) => CurriculumPackTaxonomyNode.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      notes: (json['notes'] as List)
          .map(
            (item) => CurriculumPackNote.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      citations: (json['citations'] as List)
          .map(
            (item) => CurriculumPackCitation.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
