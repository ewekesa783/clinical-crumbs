import 'package:isar/isar.dart';

import '../../../../core/database/sync_metadata_model.dart';
import '../../domain/entities/taxonomy_node.dart';

part 'taxonomy_node_model.g.dart';

/// Isar persistence model for [TaxonomyNode].
///
/// See taxonomy_node.dart for the architectural rationale for this
/// domain/data split (MV-IP-001 Task A.1A).
@collection
class TaxonomyNodeModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index()
  String? parentUuid;

  @Index()
  late String path;

  @Index()
  late int depth;

  @enumerated
  late NodeType nodeType;

  late String title;

  late String slug;

  String? shortDescription;

  String? iconKey;

  late int sortOrder;

  late int noteCount;

  String? curriculumPackUuid;

  int? curriculumPackVersion;

  late bool isUserCreated;

  late DateTime createdAt;

  late DateTime updatedAt;

  late SyncMetadataModel sync;
}
