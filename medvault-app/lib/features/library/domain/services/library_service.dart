import '../../../../core/sync/sync_metadata.dart';
import '../entities/bookmark.dart';
import '../entities/history.dart';
import '../entities/learning_resource.dart';
import '../entities/note.dart';
import '../entities/taxonomy_node.dart';
import '../repositories/bookmark_repository.dart';
import '../repositories/citation_repository.dart';
import '../repositories/history_repository.dart';
import '../repositories/learning_resource_repository.dart';
import '../repositories/note_repository.dart';
import '../repositories/taxonomy_repository.dart';
import 'dto/note_with_citations.dart';
import 'dto/topic_notes.dart';

/// Coordinates the five Phase 1 repositories (TaxonomyRepository,
/// NoteRepository, CitationRepository, BookmarkRepository,
/// HistoryRepository) for operations that require genuine
/// multi-repository coordination or data-dependent control flow — the
/// test applied throughout MV-IP-002 for "does this belong in a
/// service" (see TaxonomyNavigationService.getSiblings() removal and
/// RecentlyViewedService for the same test applied elsewhere).
///
/// FINAL SHAPE (MV-IP-002 Task A.1B refinement): identity-resolution for
/// new vs. existing records is split into two small, single-purpose
/// helpers, `_uuidFor` and `_syncFor`, rather than one combined
/// `_resolveIdentity` helper used in an earlier draft. The split was
/// made because the two concerns (choosing a uuid, choosing/creating
/// sync metadata) are independent and combining them obscured each
/// one's single responsibility.
///
/// `generateUuid`, `createSyncMetadata`, and `now` are injected
/// functions rather than calls to a concrete UUID/clock implementation:
/// no UUID-generation mechanism or composition root has been
/// established in this project (see known gaps in
/// RECONSTRUCTION_MANIFEST.md); injecting them keeps LibraryService
/// testable and decoupled from that undecided mechanism.
/// A note or PDF resolved from the shared recent-view history.
class BookmarkedLearningResource {
  const BookmarkedLearningResource({
    required this.uuid,
    required this.title,
    required this.subtitle,
    required this.isPdf,
    this.isHtmlLesson = false,
  });

  final String uuid;
  final String title;
  final String subtitle;
  final bool isPdf;
  final bool isHtmlLesson;
}

class RecentLearningResource {
  const RecentLearningResource({
    required this.uuid,
    required this.title,
    required this.viewedAt,
    required this.isPdf,
    this.isHtmlLesson = false,
  });

  final String uuid;
  final String title;
  final DateTime viewedAt;
  final bool isPdf;
  final bool isHtmlLesson;
}

class LibraryService {
  LibraryService({
    required TaxonomyRepository taxonomyRepository,
    required NoteRepository noteRepository,
    required CitationRepository citationRepository,
    required BookmarkRepository bookmarkRepository,
    required HistoryRepository historyRepository,
    LearningResourceRepository? learningResourceRepository,
    required String Function() generateUuid,
    required SyncMetadata Function() createSyncMetadata,
    required DateTime Function() now,
  })  : _taxonomyRepository = taxonomyRepository,
        _noteRepository = noteRepository,
        _citationRepository = citationRepository,
        _bookmarkRepository = bookmarkRepository,
        _historyRepository = historyRepository,
        _learningResourceRepository = learningResourceRepository,
        _generateUuid = generateUuid,
        _createSyncMetadata = createSyncMetadata,
        _now = now;

  final TaxonomyRepository _taxonomyRepository;
  final NoteRepository _noteRepository;
  final CitationRepository _citationRepository;
  final BookmarkRepository _bookmarkRepository;
  final HistoryRepository _historyRepository;
  final LearningResourceRepository? _learningResourceRepository;
  final String Function() _generateUuid;
  final SyncMetadata Function() _createSyncMetadata;
  final DateTime Function() _now;

  /// Chooses the uuid for a record being saved: reuses [existingUuid] if
  /// one was supplied (an update), otherwise generates a new one (a
  /// create). Split out from the combined `_resolveIdentity` helper in
  /// Task A.1B.
  String _uuidFor(String? existingUuid) => existingUuid ?? _generateUuid();

  /// Chooses the sync metadata for a record being saved: reuses
  /// [existingSync] if one was supplied, otherwise creates fresh sync
  /// metadata. Split out from the combined `_resolveIdentity` helper in
  /// Task A.1B.
  SyncMetadata _syncFor(SyncMetadata? existingSync) =>
      existingSync ?? _createSyncMetadata();

  /// Updates a note's title, tags, and topic without changing its content.
  ///
  /// The note UUID, mode, body, citations, pin state, and creation timestamp
  /// are preserved. Local edits retain sync identity and mark the record dirty.
  Future<Note> updateNoteMetadata({
    required String noteUuid,
    required String title,
    required List<String> tags,
    required String topicUuid,
  }) async {
    final existing = await _noteRepository.getByUuid(noteUuid);
    if (existing == null) {
      throw StateError('No note found for uuid "$noteUuid".');
    }
    if (existing.sync.isDeleted) {
      throw StateError('A deleted note cannot be edited.');
    }

    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Title cannot be empty.');
    }

    final destination = await _taxonomyRepository.getByUuid(topicUuid);
    if (destination == null || destination.nodeType != NodeType.topic) {
      throw StateError('The destination topic does not exist or is invalid.');
    }

    if (topicUuid != existing.topicUuid) {
      final conflict = await _noteRepository.getByTopicAndMode(
        topicUuid,
        existing.mode,
      );
      if (conflict != null && conflict.uuid != existing.uuid) {
        throw StateError(
          'The destination topic already has a note in this mode.',
        );
      }
    }

    final normalizedTags = <String>[];
    final seenTags = <String>{};
    for (final tag in tags) {
      final normalized = tag.trim();
      if (normalized.isNotEmpty && seenTags.add(normalized.toLowerCase())) {
        normalizedTags.add(normalized);
      }
    }

    final updatedAt = _now();
    final updated = Note(
      uuid: existing.uuid,
      topicUuid: topicUuid,
      mode: existing.mode,
      title: normalizedTitle,
      bodyMarkdown: existing.bodyMarkdown,
      plainTextExtract: existing.plainTextExtract,
      tags: normalizedTags,
      citationOrder: existing.citationOrder,
      isPinned: existing.isPinned,
      createdAt: existing.createdAt,
      updatedAt: updatedAt,
      sync: SyncMetadata(
        remoteId: existing.sync.remoteId,
        lastModifiedLocal: updatedAt,
        lastSyncedAt: existing.sync.lastSyncedAt,
        isDirty: true,
        isDeleted: false,
        deviceId: existing.sync.deviceId,
        syncRevision: existing.sync.syncRevision + 1,
      ),
    );

    await _noteRepository.save(updated);
    return updated;
  }

  /// Returns all notes for [topicUuid], grouped into a [TopicNotes] DTO.
  ///
  /// Genuine service-layer work: requires knowing the topic exists
  /// (TaxonomyRepository) before collecting its notes across all modes
  /// (NoteRepository), which a single repository call cannot express.
  Future<TopicNotes> getTopicNotes(String topicUuid) async {
    final topic = await _taxonomyRepository.getByUuid(topicUuid);
    if (topic == null) {
      throw StateError('No taxonomy node found for uuid "$topicUuid".');
    }

    final notes = <Note>[];
    for (final mode in Mode.values) {
      final note = await _noteRepository.getByTopicAndMode(topicUuid, mode);
      if (note != null) {
        notes.add(note);
      }
    }

    return TopicNotes(topicUuid: topicUuid, notes: notes);
  }

  /// Returns a note together with its resolved citations, in the note's
  /// `citationOrder`.
  ///
  /// Genuine service-layer work: requires resolving citation UUIDs
  /// (CitationRepository.getByUuids) against a note fetched from a
  /// different repository (NoteRepository) — no single repository call
  /// can express this join.
  Future<NoteWithCitations?> getNoteWithCitations(String noteUuid) async {
    final note = await _noteRepository.getByUuid(noteUuid);
    if (note == null) return null;

    final citations = await _citationRepository.getByUuids(
      note.citationOrder,
    );

    return NoteWithCitations(note: note, citations: citations);
  }

  /// Records that [noteUuid] was viewed at [viewedAt] (defaulting to
  /// now), upserting the note's single History entry (noteUuid is a
  /// unique index on HistoryModel; see HistoryRepository's documented
  /// save() contract).
  ///
  /// Genuine service-layer work: must look up the existing History
  /// entry for the note (if any) to reuse its uuid before saving,
  /// because HistoryRepository.save() does not itself perform
  /// upsert-by-noteUuid.
  Future<void> recordNoteViewed(String noteUuid, {DateTime? viewedAt}) async {
    await recordResourceViewed(noteUuid, viewedAt: viewedAt);
  }

  /// Records a view of a note or another locally stored learning resource.
  ///
  /// History storage reuses the existing `noteUuid` field to preserve the
  /// current Isar schema and existing note history.
  Future<void> recordResourceViewed(
    String resourceUuid, {
    DateTime? viewedAt,
  }) async {
    final existing = await _historyRepository.getByNoteUuid(resourceUuid);

    final entry = History(
      uuid: _uuidFor(existing?.uuid),
      noteUuid: resourceUuid,
      viewedAt: viewedAt ?? _now(),
      sync: _syncFor(existing?.sync),
    );

    await _historyRepository.save(entry);
  }

  /// Resolves the most recently viewed history entries to existing notes.
  ///
  /// History records whose notes no longer exist are skipped.
  Future<List<Note>> getRecentlyViewedNotes({int? limit = 10}) async {
    if (limit != null && limit <= 0) return [];

    final history = await _historyRepository.getRecent(limit: limit);
    final notes = <Note>[];

    for (final entry in history) {
      final note = await _noteRepository.getByUuid(entry.noteUuid);
      if (note != null) notes.add(note);
    }

    return notes;
  }

  /// Resolves recent history entries to existing notes and imported PDFs.
  ///
  /// Entries whose resources have been deleted are skipped.
  Future<List<RecentLearningResource>> getRecentlyViewedResources({
    int? limit = 10,
  }) async {
    if (limit != null && limit <= 0) return [];

    final history = await _historyRepository.getRecent(limit: limit);
    final resources = <RecentLearningResource>[];

    for (final entry in history) {
      final note = await _noteRepository.getByUuid(entry.noteUuid);
      if (note != null) {
        resources.add(RecentLearningResource(
          uuid: note.uuid,
          title: note.title,
          viewedAt: entry.viewedAt,
          isPdf: false,
        ));
        continue;
      }

      final resource =
          await _learningResourceRepository?.getByUuid(entry.noteUuid);
      if (resource != null) {
        final isHtmlLesson =
            resource.format == LearningResourceFormat.htmlLesson;
        resources.add(RecentLearningResource(
          uuid: resource.uuid,
          title: resource.title,
          viewedAt: entry.viewedAt,
          isPdf: !isHtmlLesson,
          isHtmlLesson: isHtmlLesson,
        ));
      }
    }

    return resources;
  }

  /// Resolves recent bookmarks to unique, existing notes and PDFs.
  ///
  /// The most recently created bookmark for each resource determines its
  /// position. Missing resources and duplicate bookmarks are skipped.
  Future<List<BookmarkedLearningResource>> getBookmarkedResources({
    int limit = 10,
  }) async {
    if (limit <= 0) return [];

    // Read beyond the display limit so PDF bookmarks and duplicate or stale
    // entries don't prevent later valid bookmarks from appearing.
    final bookmarks = await _bookmarkRepository.getRecent(limit: 1000);
    final resources = <BookmarkedLearningResource>[];
    final seenUuids = <String>{};

    for (final bookmark in bookmarks) {
      if (!seenUuids.add(bookmark.noteUuid)) continue;

      final note = await _noteRepository.getByUuid(bookmark.noteUuid);
      if (note != null) {
        resources.add(BookmarkedLearningResource(
          uuid: note.uuid,
          title: note.title,
          subtitle: note.mode.name,
          isPdf: false,
        ));
      } else {
        final resource =
            await _learningResourceRepository?.getByUuid(bookmark.noteUuid);
        if (resource != null) {
          final isHtmlLesson =
              resource.format == LearningResourceFormat.htmlLesson;
          resources.add(BookmarkedLearningResource(
            uuid: resource.uuid,
            title: resource.title,
            subtitle: isHtmlLesson ? 'HTML lesson' : 'PDF document',
            isPdf: !isHtmlLesson,
            isHtmlLesson: isHtmlLesson,
          ));
        }
      }

      if (resources.length >= limit) break;
    }

    return resources;
  }

  /// Resolves recent bookmarks to unique, existing notes.
  ///
  /// Multiple bookmarks for one note produce a single dashboard entry.
  /// Bookmarks whose notes no longer exist are skipped.
  Future<List<Note>> getBookmarkedNotes({int limit = 10}) async {
    if (limit <= 0) return [];

    final bookmarks = await _bookmarkRepository.getRecent(limit: limit);
    final notes = <Note>[];
    final seenNoteUuids = <String>{};

    for (final bookmark in bookmarks) {
      if (!seenNoteUuids.add(bookmark.noteUuid)) continue;

      final note = await _noteRepository.getByUuid(bookmark.noteUuid);
      if (note != null) notes.add(note);
    }

    return notes;
  }

  /// Returns whether a learning resource is bookmarked.
  Future<bool> isLearningResourceBookmarked(String resourceUuid) async {
    final bookmarks = await _bookmarkRepository.getByNoteUuid(resourceUuid);
    return bookmarks.isNotEmpty;
  }

  /// Creates a bookmark for a PDF or HTML learning resource.
  Future<Bookmark> bookmarkLearningResource(
    String resourceUuid, {
    String? label,
  }) async {
    final existing =
        await _learningResourceRepository?.getByUuid(resourceUuid);
    if (existing == null) {
      throw StateError(
        'No learning resource found for uuid "$resourceUuid".',
      );
    }

    final bookmarks =
        await _bookmarkRepository.getByNoteUuid(resourceUuid);
    if (bookmarks.isNotEmpty) return bookmarks.first;

    final bookmark = Bookmark(
      uuid: _generateUuid(),
      noteUuid: resourceUuid,
      label: label,
      createdAt: _now(),
      sync: _createSyncMetadata(),
    );

    await _bookmarkRepository.save(bookmark);
    return bookmark;
  }

  /// Backward-compatible PDF bookmark check.
  Future<bool> isPdfBookmarked(String resourceUuid) =>
      isLearningResourceBookmarked(resourceUuid);

  /// Backward-compatible PDF bookmark creation.
  Future<Bookmark> bookmarkPdf(String resourceUuid, {String? label}) =>
      bookmarkLearningResource(resourceUuid, label: label);

  /// Removes bookmarks associated with a PDF learning resource.
  Future<void> unbookmarkPdf(String resourceUuid) async {
    await _bookmarkRepository.deleteByNoteUuid(resourceUuid);
  }

  /// Permanently deletes a note and removes its associated bookmarks.
  ///
  /// Citations are retained because they may be shared by other notes.
  Future<void> deleteNote(String noteUuid) async {
    final existing = await _noteRepository.getByUuid(noteUuid);
    if (existing == null) {
      throw StateError('No note found for uuid "$noteUuid".');
    }

    await _bookmarkRepository.deleteByNoteUuid(noteUuid);
    await _noteRepository.deleteByUuid(noteUuid);
  }

  /// Returns whether [noteUuid] has at least one bookmark.
  Future<bool> isNoteBookmarked(String noteUuid) async {
    final bookmarks = await _bookmarkRepository.getByNoteUuid(noteUuid);
    return bookmarks.isNotEmpty;
  }

  /// Removes all bookmarks associated with [noteUuid].
  Future<void> unbookmarkNote(String noteUuid) async {
    await _bookmarkRepository.deleteByNoteUuid(noteUuid);
  }

  /// Removes a bookmark for a note or PDF without deleting the resource.
  Future<void> unbookmarkResource(String resourceUuid) async {
    await _bookmarkRepository.deleteByNoteUuid(resourceUuid);
  }

  /// Removes every bookmark while preserving all underlying resources.
  Future<void> clearAllBookmarks() async {
    await _bookmarkRepository.deleteAll();
  }

  /// Removes one resource from recent history without deleting the resource.
  Future<void> removeHistoryEntry(String resourceUuid) async {
    await _historyRepository.deleteByNoteUuid(resourceUuid);
  }

  /// Clears recent history while preserving resources and reading positions.
  Future<void> clearHistory() async {
    await _historyRepository.deleteAll();
  }

  /// Creates a new bookmark for [noteUuid] (a note may have more than
  /// one; see BookmarkModel.noteUuid's non-unique index).
  Future<Bookmark> bookmarkNote(String noteUuid, {String? label}) async {
    final bookmark = Bookmark(
      uuid: _generateUuid(),
      noteUuid: noteUuid,
      label: label,
      createdAt: _now(),
      sync: _createSyncMetadata(),
    );

    await _bookmarkRepository.save(bookmark);
    return bookmark;
  }
}
