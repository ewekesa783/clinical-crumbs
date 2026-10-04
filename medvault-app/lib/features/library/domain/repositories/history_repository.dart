import '../entities/history.dart';

abstract class HistoryRepository {
  /// Does NOT itself perform upsert-by-noteUuid logic; if an entry with
  /// the same `uuid` already exists, it is replaced, but a *new*
  /// `History` for a note that already has an entry (different uuid,
  /// same noteUuid) will violate the unique index on `noteUuid` at the
  /// storage layer. Callers that want "update the existing view
  /// timestamp" behavior must look up the existing entry via
  /// [getByNoteUuid] first and reuse its `uuid`. This contract was
  /// clarified during MV-IP-001 Task A.5B specifically to resolve
  /// ambiguity about whether `save()` enforces upsert-by-note semantics
  /// (it does not).
  Future<void> save(History history);

  Future<History?> getByUuid(String uuid);

  /// Renamed from the earlier `getMostRecentByNoteUuid` during Task
  /// A.5A: since `noteUuid` is now unique, there is at most one entry
  /// per note, so "most recent" was a misleading name for what is simply
  /// a lookup by note.
  Future<History?> getByNoteUuid(String noteUuid);
}
