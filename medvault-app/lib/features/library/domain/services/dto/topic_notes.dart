import '../../entities/note.dart';

/// DTO grouping all notes (across modes) that exist for a single topic.
///
/// [ASSUMPTION] Shape reconstructed from MV-IP-002 Task A.1 context; no
/// single specification clause enumerates this DTO verbatim.
class TopicNotes {
  const TopicNotes({
    required this.topicUuid,
    required this.notes,
  });

  final String topicUuid;
  final List<Note> notes;
}
