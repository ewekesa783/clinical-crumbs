import '../../../../core/database/sync_metadata_mapper.dart';
import '../../domain/entities/history.dart';
import 'history_model.dart';

class HistoryMapper {
  const HistoryMapper._();

  static History toDomain(HistoryModel model) {
    return History(
      uuid: model.uuid,
      noteUuid: model.noteUuid,
      viewedAt: model.viewedAt,
      sync: SyncMetadataMapper.toDomain(model.sync),
    );
  }

  static HistoryModel toModel(History domain) {
    return HistoryModel()
      ..uuid = domain.uuid
      ..noteUuid = domain.noteUuid
      ..viewedAt = domain.viewedAt
      ..sync = SyncMetadataMapper.toModel(domain.sync);
  }
}
