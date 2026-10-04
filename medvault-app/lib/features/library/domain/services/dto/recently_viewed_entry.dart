import '../../entities/note.dart';

/// DTO representing one entry in the recently-viewed-notes list.
///
/// FINAL SHAPE (MV-IP-002 Task A.3A refinement): this DTO exposes only
/// the resolved [Note] and the view [viewedAt] timestamp. An earlier
/// draft exposed the underlying [History] entity directly; that was
/// narrowed because callers (presentation layer) need the Note content,
/// not History's internal identity fields, and exposing History would
/// have leaked a data-layer-adjacent concept across the service
/// boundary unnecessarily.
class RecentlyViewedEntry {
  const RecentlyViewedEntry({
    required this.note,
    required this.viewedAt,
  });

  final Note note;
  final DateTime viewedAt;
}
