import '../sync/sync_metadata.dart';
import 'sync_metadata_model.dart';

/// Converts between the domain [SyncMetadata] and its Isar-embedded
/// persistence counterpart [SyncMetadataModel].
///
/// Extracted during MV-IP-001 Task A.1A so that every entity mapper
/// (TaxonomyNodeMapper, NoteMapper, CitationMapper, BookmarkMapper,
/// HistoryMapper) delegates sync-field conversion here rather than
/// duplicating it.
class SyncMetadataMapper {
  const SyncMetadataMapper._();

  static SyncMetadata toDomain(SyncMetadataModel model) {
    return SyncMetadata(
      remoteId: model.remoteId,
      lastModifiedLocal: model.lastModifiedLocal,
      lastSyncedAt: model.lastSyncedAt,
      isDirty: model.isDirty,
      isDeleted: model.isDeleted,
      deviceId: model.deviceId,
      syncRevision: model.syncRevision,
    );
  }

  static SyncMetadataModel toModel(SyncMetadata domain) {
    return SyncMetadataModel()
      ..remoteId = domain.remoteId
      ..lastModifiedLocal = domain.lastModifiedLocal
      ..lastSyncedAt = domain.lastSyncedAt
      ..isDirty = domain.isDirty
      ..isDeleted = domain.isDeleted
      ..deviceId = domain.deviceId
      ..syncRevision = domain.syncRevision;
  }
}
