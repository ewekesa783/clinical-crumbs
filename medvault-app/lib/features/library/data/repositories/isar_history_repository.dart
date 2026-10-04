import 'package:isar/isar.dart';

import '../../domain/entities/history.dart';
import '../../domain/repositories/history_repository.dart';
import '../models/history_mapper.dart';
import '../models/history_model.dart';

class IsarHistoryRepository implements HistoryRepository {
  IsarHistoryRepository(this._isar);

  final Isar _isar;

  @override
  Future<void> save(History history) async {
    final model = HistoryMapper.toModel(history);

    final existing =
        await _isar.historyModels.where().uuidEqualTo(model.uuid).findFirst();
    if (existing != null) {
      model.id = existing.id;
    }

    await _isar.writeTxn(() async {
      await _isar.historyModels.put(model);
    });
  }

  @override
  Future<History?> getByUuid(String uuid) async {
    final model =
        await _isar.historyModels.where().uuidEqualTo(uuid).findFirst();
    if (model == null) return null;
    return HistoryMapper.toDomain(model);
  }

  @override
  Future<History?> getByNoteUuid(String noteUuid) async {
    final model = await _isar.historyModels
        .where()
        .noteUuidEqualTo(noteUuid)
        .findFirst();
    if (model == null) return null;
    return HistoryMapper.toDomain(model);
  }
}
