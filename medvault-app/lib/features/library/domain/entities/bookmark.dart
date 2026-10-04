import '../../../../core/sync/sync_metadata.dart';

/// Plain domain representation of a user's bookmark on a note.
///
/// Personal-data durability convention: [noteUuid] is a plain string
/// reference, NOT an `IsarLink`, so a bookmark remains resolvable even if
/// the underlying Note is replaced by a future content update that
/// assigns it a new internal Isar `Id`. A user may bookmark the same
/// note more than once is NOT prevented at this layer — see the
/// non-unique index on [BookmarkModel.noteUuid] (MV-IP-001 Task A.4A
/// correction: this index was originally unique and was corrected to
/// non-unique).
class Bookmark {
  const Bookmark({
    required this.uuid,
    required this.noteUuid,
    this.label,
    required this.createdAt,
    required this.sync,
  });

  final String uuid;
  final String noteUuid;
  final String? label;
  final DateTime createdAt;
  final SyncMetadata sync;
}
