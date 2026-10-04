import '../../../../core/database/sync_metadata_mapper.dart';
import '../../domain/entities/citation.dart';
import 'citation_model.dart';

class CitationMapper {
  const CitationMapper._();

  static Citation toDomain(CitationModel model) {
    return Citation(
      uuid: model.uuid,
      sourceType: model.sourceType,
      title: model.title,
      authors: model.authors,
      publicationYear: model.publicationYear,
      pageReference: model.pageReference,
      url: model.url,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      sync: SyncMetadataMapper.toDomain(model.sync),
    );
  }

  static CitationModel toModel(Citation domain) {
    return CitationModel()
      ..uuid = domain.uuid
      ..sourceType = domain.sourceType
      ..title = domain.title
      ..authors = domain.authors
      ..publicationYear = domain.publicationYear
      ..pageReference = domain.pageReference
      ..url = domain.url
      ..createdAt = domain.createdAt
      ..updatedAt = domain.updatedAt
      ..sync = SyncMetadataMapper.toModel(domain.sync);
  }
}
