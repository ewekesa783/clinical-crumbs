import '../../../../core/sync/sync_metadata.dart';

/// Plain domain representation of a note-viewing history entry.
///
/// Personal-data durability convention: [noteUuid] is a plain string
/// reference, NOT an `IsarLink` (see bookmark.dart for the same
/// rationale). [noteUuid] carries a UNIQUE index here (MV-IP-001 Task
/// A.5A correction: at most one history entry per note — `save()`
/// updates the existing entry's `viewedAt` rather than creating a new
/// row for repeat views). `save()` does NOT itself enforce this as an
/// upsert; the caller is responsible for supplying the existing entry's
/// identity when updating (clarified in Task A.5B) — the unique index
/// only prevents duplicate rows at the storage layer, it does not
/// perform find-or-create logic.
class History {
  const History({
    required this.uuid,
    required this.noteUuid,
    required this.viewedAt,
    required this.sync,
  });

  final String uuid;
  final String noteUuid;
  final DateTime viewedAt;
  final SyncMetadata sync;
}
