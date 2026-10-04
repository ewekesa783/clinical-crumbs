import '../../entities/citation.dart';
import '../../entities/note.dart';

/// DTO pairing a [Note] with its resolved [Citation] entities, in the
/// note's `citationOrder`.
class NoteWithCitations {
  const NoteWithCitations({
    required this.note,
    required this.citations,
  });

  final Note note;
  final List<Citation> citations;
}
