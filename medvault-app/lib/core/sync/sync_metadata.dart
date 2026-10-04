/// Domain-layer representation of per-record sync state.
///
/// This is a plain Dart class with no persistence-framework dependencies.
/// It is shared by every syncable collection (TaxonomyNode, Note,
/// Citation, Bookmark, History) to avoid duplicating sync-state fields
/// and conversion logic across each entity. Extracted during MV-IP-001
/// Task A.1A as part of the domain/data layering correction.
class SyncMetadata {
  const SyncMetadata({
    this.remoteId,
    required this.lastModifiedLocal,
    this.lastSyncedAt,
    required this.isDirty,
    required this.isDeleted,
    required this.deviceId,
    required this.syncRevision,
  });

  /// Server-assigned identifier once this record has been synced at least
  /// once. Null for records that have never been synced.
  final String? remoteId;

  /// Timestamp of the most recent local modification.
  final DateTime lastModifiedLocal;

  /// Timestamp of the most recent successful sync, if any.
  final DateTime? lastSyncedAt;

  /// True if local changes have not yet been pushed to the server.
  final bool isDirty;

  /// True if this record is a tombstone (soft-deleted, pending sync of
  /// the deletion).
  final bool isDeleted;

  /// Identifier of the device that produced the current local state.
  final String deviceId;

  /// Monotonically increasing per-record revision counter used for
  /// conflict detection.
  final int syncRevision;
}
