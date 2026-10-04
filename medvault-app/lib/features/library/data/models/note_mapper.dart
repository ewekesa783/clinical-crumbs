import '../../../../core/database/sync_metadata_mapper.dart';
import '../../domain/entities/note.dart';
import 'note_model.dart';

/// Converts between the domain [Note] and its Isar persistence model
/// [NoteModel].
///
/// Defensive copying: `tags` and `citationOrder` are copied with
/// `List<String>.from(...)` at BOTH conversion directions (MV-IP-001 Task
/// A.2A refinement) so that the domain and persistence objects never
/// share the same mutable list instance. Without this, a caller mutating
/// a list obtained from one layer could silently corrupt the other.
class NoteMapper {
  const NoteMapper._();

  static Note toDomain(NoteModel model) {
    return Note(
      uuid: model.uuid,
      topicUuid: model.topicUuid,
      mode: model.mode,
      title: model.title,
      bodyMarkdown: model.bodyMarkdown,
      plainTextExtract: model.plainTextExtract,
      tags: List<String>.from(model.tags),
      citationOrder: List<String>.from(model.citationOrder),
      isPinned: model.isPinned,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      sync: SyncMetadataMapper.toDomain(model.sync),
    );
  }

  static NoteModel toModel(Note domain) {
    return NoteModel()
      ..uuid = domain.uuid
      ..topicUuid = domain.topicUuid
      ..mode = domain.mode
      ..title = domain.title
      ..bodyMarkdown = domain.bodyMarkdown
      ..plainTextExtract = domain.plainTextExtract
      ..tags = List<String>.from(domain.tags)
      ..citationOrder = List<String>.from(domain.citationOrder)
      ..isPinned = domain.isPinned
      ..createdAt = domain.createdAt
      ..updatedAt = domain.updatedAt
      ..sync = SyncMetadataMapper.toModel(domain.sync);
  }
}
