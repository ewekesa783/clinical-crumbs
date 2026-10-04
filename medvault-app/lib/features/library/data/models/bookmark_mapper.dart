import '../../../../core/database/sync_metadata_mapper.dart';
import '../../domain/entities/bookmark.dart';
import 'bookmark_model.dart';

class BookmarkMapper {
  const BookmarkMapper._();

  static Bookmark toDomain(BookmarkModel model) {
    return Bookmark(
      uuid: model.uuid,
      noteUuid: model.noteUuid,
      label: model.label,
      createdAt: model.createdAt,
      sync: SyncMetadataMapper.toDomain(model.sync),
    );
  }

  static BookmarkModel toModel(Bookmark domain) {
    return BookmarkModel()
      ..uuid = domain.uuid
      ..noteUuid = domain.noteUuid
      ..label = domain.label
      ..createdAt = domain.createdAt
      ..sync = SyncMetadataMapper.toModel(domain.sync);
  }
}
