import 'package:isar/isar.dart';

import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../models/bookmark_mapper.dart';
import '../models/bookmark_model.dart';

class IsarBookmarkRepository implements BookmarkRepository {
  IsarBookmarkRepository(this._isar);

  final Isar _isar;

  @override
  Future<void> save(Bookmark bookmark) async {
    final model = BookmarkMapper.toModel(bookmark);

    final existing = await _isar.bookmarkModels
        .where()
        .uuidEqualTo(model.uuid)
        .findFirst();
    if (existing != null) {
      model.id = existing.id;
    }

    await _isar.writeTxn(() async {
      await _isar.bookmarkModels.put(model);
    });
  }

  @override
  Future<Bookmark?> getByUuid(String uuid) async {
    final model =
        await _isar.bookmarkModels.where().uuidEqualTo(uuid).findFirst();
    if (model == null) return null;
    return BookmarkMapper.toDomain(model);
  }

  @override
  Future<List<Bookmark>> getByNoteUuid(String noteUuid) async {
    final models = await _isar.bookmarkModels
        .where()
        .noteUuidEqualTo(noteUuid)
        .findAll();
    return models.map(BookmarkMapper.toDomain).toList();
  }
}
