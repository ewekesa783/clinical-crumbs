import '../../../../core/sync/sync_metadata.dart';

/// Note-taking mode under which a note was authored.
///
/// PERSISTENCE-ORDER-SIGNIFICANT (stored via `@enumerated`). Append only;
/// never reorder or remove existing values.
enum Mode { detailedNotes, visualLearning, quickReview }

/// Plain domain representation of a user's note for a given taxonomy
/// topic and mode.
///
/// [ASSUMPTION] The field set below is reconstructed from the project's
/// note-taking requirements as understood at MV-IP-001 Task A.2; no
/// single specification enumerates every field verbatim, so fields not
/// directly traceable are treated as provisional. `citationOrder` holds
/// citation UUIDs in display order; resolving them to full Citation
/// entities is deferred to the service layer (see
/// LibraryService.getNoteWithCitations in MV-IP-002), not performed here.
class Note {
  const Note({
    required this.uuid,
    required this.topicUuid,
    required this.mode,
    required this.title,
    required this.bodyMarkdown,
    this.plainTextExtract,
    required this.tags,
    required this.citationOrder,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
    required this.sync,
  });

  final String uuid;
  final String topicUuid;
  final Mode mode;
  final String title;
  final String bodyMarkdown;

  /// Plain-text extract of [bodyMarkdown], maintained for search indexing.
  final String? plainTextExtract;

  final List<String> tags;

  /// Citation UUIDs, in display order.
  final List<String> citationOrder;

  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncMetadata sync;
}
