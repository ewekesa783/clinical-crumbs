import '../../../../core/sync/sync_metadata.dart';

/// Kind of source a citation refers to.
///
/// PERSISTENCE-ORDER-SIGNIFICANT (stored via `@enumerated`). Append only.
enum SourceType { textbook, journalArticle, guideline, lectureSlide, other }

/// Plain domain representation of a single citation referenced by one or
/// more notes.
///
/// [ASSUMPTION] Field set reconstructed from MV-IP-001 Task A.3 context;
/// not all fields are directly traceable to a single specification
/// clause and are treated as provisional.
class Citation {
  const Citation({
    required this.uuid,
    required this.sourceType,
    required this.title,
    this.authors,
    this.publicationYear,
    this.pageReference,
    this.url,
    required this.createdAt,
    required this.updatedAt,
    required this.sync,
  });

  final String uuid;
  final SourceType sourceType;
  final String title;
  final String? authors;
  final int? publicationYear;
  final String? pageReference;
  final String? url;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncMetadata sync;
}
