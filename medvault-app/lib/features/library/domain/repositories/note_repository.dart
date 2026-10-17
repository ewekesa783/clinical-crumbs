import '../entities/note.dart';

abstract class NoteRepository {
  Future<void> save(Note note);

  Future<Note?> getByUuid(String uuid);

  Future<Note?> getByTopicAndMode(String topicUuid, Mode mode);

  /// Returns all notes for library-wide filtering.
  Future<List<Note>> getAll();

  /// Searches note titles, plain-text extracts (or Markdown when absent),
  /// and tags. An empty or whitespace-only query returns no results.
  Future<List<Note>> search(String query);
}
