import '../repositories/history_repository.dart';
import '../repositories/note_repository.dart';
import 'dto/recently_viewed_entry.dart';

/// Resolves recently-viewed History entries into [RecentlyViewedEntry]
/// DTOs carrying the full [Note], not just its uuid.
///
/// Genuine service-layer work: requires fetching History entries and
/// then resolving each one's `noteUuid` against NoteRepository — a join
/// across two repositories that no single repository call could
/// express.
///
/// See dto/recently_viewed_entry.dart for the Task A.3A narrowing of the
/// DTO shape (Note + viewedAt only, no History exposed to callers).
class RecentlyViewedService {
  RecentlyViewedService({
    required HistoryRepository historyRepository,
    required NoteRepository noteRepository,
  })  : _historyRepository = historyRepository,
        _noteRepository = noteRepository;

  final HistoryRepository _historyRepository;
  final NoteRepository _noteRepository;

  /// Returns the recently-viewed entry for [noteUuid], if one exists.
  ///
  /// [ASSUMPTION] No specification defines a "list all recently viewed
  /// notes across the whole library, ordered by recency" query, and no
  /// such repository method exists to support one efficiently (it would
  /// require a new indexed query, which is out of scope — see Task A.4's
  /// explicit finding that no further repository-method work was
  /// justified). This method therefore resolves a single note's history
  /// entry rather than a library-wide recency list.
  Future<RecentlyViewedEntry?> getRecentlyViewedEntry(String noteUuid) async {
    final historyEntry = await _historyRepository.getByNoteUuid(noteUuid);
    if (historyEntry == null) return null;

    final note = await _noteRepository.getByUuid(historyEntry.noteUuid);
    if (note == null) return null;

    return RecentlyViewedEntry(note: note, viewedAt: historyEntry.viewedAt);
  }
}
