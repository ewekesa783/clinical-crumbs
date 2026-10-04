import '../entities/note.dart';

abstract class NoteRepository {
  Future<void> save(Note note);

  Future<Note?> getByUuid(String uuid);

  Future<Note?> getByTopicAndMode(String topicUuid, Mode mode);
}
