import '../../../../core/sync/sync_metadata.dart';

/// Node type within the taxonomy tree.
///
/// PERSISTENCE-ORDER-SIGNIFICANT: this enum is stored by Isar via
/// `@enumerated`, which persists the declaration index, not the name.
/// Never reorder, remove, or insert values before existing ones — doing
/// so silently corrupts already-persisted data. Append only.
enum NodeType { subject, system, topic, custom }

/// Plain domain representation of a taxonomy tree node (subject / organ
/// system / topic / user-defined custom node).
///
/// This class has zero Isar or Flutter imports, by design: see
/// MV-IP-001 Task A.1A, which corrected an earlier architecture violation
/// where this type was simultaneously a domain entity and an Isar
/// persistence model (in breach of Engineering Implementation
/// Specification §6/§8). The Isar-specific counterpart lives separately
/// in data/models/taxonomy_node_model.dart, with conversion performed by
/// TaxonomyNodeMapper.
///
/// [ASSUMPTION] The `path` field stores a precomputed materialized path
/// (e.g. "subject-uuid/system-uuid/topic-uuid") for ancestor/descendant
/// queries. This diverges from medvault_shared's curriculum-pack-format
/// schema, which does not define a `path` concept; the divergence is
/// intentional and local to the app's persistence layer.
class TaxonomyNode {
  const TaxonomyNode({
    required this.uuid,
    this.parentUuid,
    required this.path,
    required this.depth,
    required this.nodeType,
    required this.title,
    required this.slug,
    this.shortDescription,
    this.iconKey,
    required this.sortOrder,
    required this.noteCount,
    this.curriculumPackUuid,
    this.curriculumPackVersion,
    required this.isUserCreated,
    required this.createdAt,
    required this.updatedAt,
    required this.sync,
  });

  final String uuid;
  final String? parentUuid;
  final String path;
  final int depth;
  final NodeType nodeType;
  final String title;
  final String slug;
  final String? shortDescription;
  final String? iconKey;
  final int sortOrder;
  final int noteCount;
  final String? curriculumPackUuid;
  final int? curriculumPackVersion;
  final bool isUserCreated;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncMetadata sync;
}
