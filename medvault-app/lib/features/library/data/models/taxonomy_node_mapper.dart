import '../../../../core/database/sync_metadata_mapper.dart';
import '../../domain/entities/taxonomy_node.dart';
import 'taxonomy_node_model.dart';

/// Converts between the domain [TaxonomyNode] and its Isar persistence
/// model [TaxonomyNodeModel]. All field-by-field conversion is
/// centralized here; no other code should construct one type from the
/// other directly.
class TaxonomyNodeMapper {
  const TaxonomyNodeMapper._();

  static TaxonomyNode toDomain(TaxonomyNodeModel model) {
    return TaxonomyNode(
      uuid: model.uuid,
      parentUuid: model.parentUuid,
      path: model.path,
      depth: model.depth,
      nodeType: model.nodeType,
      title: model.title,
      slug: model.slug,
      shortDescription: model.shortDescription,
      iconKey: model.iconKey,
      sortOrder: model.sortOrder,
      noteCount: model.noteCount,
      curriculumPackUuid: model.curriculumPackUuid,
      curriculumPackVersion: model.curriculumPackVersion,
      isUserCreated: model.isUserCreated,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      sync: SyncMetadataMapper.toDomain(model.sync),
    );
  }

  static TaxonomyNodeModel toModel(TaxonomyNode domain) {
    return TaxonomyNodeModel()
      ..uuid = domain.uuid
      ..parentUuid = domain.parentUuid
      ..path = domain.path
      ..depth = domain.depth
      ..nodeType = domain.nodeType
      ..title = domain.title
      ..slug = domain.slug
      ..shortDescription = domain.shortDescription
      ..iconKey = domain.iconKey
      ..sortOrder = domain.sortOrder
      ..noteCount = domain.noteCount
      ..curriculumPackUuid = domain.curriculumPackUuid
      ..curriculumPackVersion = domain.curriculumPackVersion
      ..isUserCreated = domain.isUserCreated
      ..createdAt = domain.createdAt
      ..updatedAt = domain.updatedAt
      ..sync = SyncMetadataMapper.toModel(domain.sync);
  }
}
