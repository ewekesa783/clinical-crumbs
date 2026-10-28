import 'package:isar/isar.dart';

import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_mapper.dart';
import '../models/note_model.dart';

/// Isar-backed implementation of [NoteRepository].
///
/// Correctly uses `.where()` (an indexed lookup) for both queries below,
/// in contrast to [IsarTaxonomyRepository.dart]'s preserved `.filter()`
/// defect — `uuid` and the composite `(topicUuid, mode)` index are both
/// declared `@Index` on [NoteModel], so `.where()` is applicable here.
class IsarNoteRepository implements NoteRepository {
  IsarNoteRepository(this._isar);

  final Isar _isar;

  @override
  Future<void> save(Note note) async {
    final model = NoteMapper.toModel(note);

    final existing =
        await _isar.noteModels.where().uuidEqualTo(model.uuid).findFirst();
    if (existing != null) {
      model.id = existing.id;
    }

    await _isar.writeTxn(() async {
      await _isar.noteModels.put(model);
    });
  }

  @override
  Future<void> deleteByUuid(String uuid) async {
    await _isar.writeTxn(() async {
      await _isar.noteModels.where().uuidEqualTo(uuid).deleteAll();
    });
  }

  @override
  Future<Note?> getByUuid(String uuid) async {
    final model = await _isar.noteModels.where().uuidEqualTo(uuid).findFirst();
    if (model == null) return null;
    return NoteMapper.toDomain(model);
  }

  @override
  Future<Note?> getByTopicAndMode(String topicUuid, Mode mode) async {
    final model = await _isar.noteModels
        .where()
        .topicUuidModeEqualTo(topicUuid, mode)
        .findFirst();
    if (model == null) return null;
    return NoteMapper.toDomain(model);
  }

  @override
  Future<List<Note>> getAll() async {
    final models = await _isar.noteModels.where().findAll();
    return models.map(NoteMapper.toDomain).toList();
  }

  @override
  Future<List<Note>> search(String query) async {
    final term = query.trim();
    if (term.isEmpty) return [];

    final models = await _isar.noteModels
        .filter()
        .group(
          (q) => q
              .titleContains(term, caseSensitive: false)
              .or()
              .plainTextExtractContains(term, caseSensitive: false)
              .or()
              .bodyMarkdownContains(term, caseSensitive: false)
              .or()
              .tagsElementContains(term, caseSensitive: false),
        )
        .findAll();

    return models.map(NoteMapper.toDomain).toList();
  }
}
