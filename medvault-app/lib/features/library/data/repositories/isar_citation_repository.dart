import 'package:isar/isar.dart';

import '../../domain/entities/citation.dart';
import '../../domain/repositories/citation_repository.dart';
import '../models/citation_mapper.dart';
import '../models/citation_model.dart';

class IsarCitationRepository implements CitationRepository {
  IsarCitationRepository(this._isar);

  final Isar _isar;

  @override
  Future<void> save(Citation citation) async {
    final model = CitationMapper.toModel(citation);

    final existing =
        await _isar.citationModels.where().uuidEqualTo(model.uuid).findFirst();
    if (existing != null) {
      model.id = existing.id;
    }

    await _isar.writeTxn(() async {
      await _isar.citationModels.put(model);
    });
  }

  @override
  Future<Citation?> getByUuid(String uuid) async {
    final model =
        await _isar.citationModels.where().uuidEqualTo(uuid).findFirst();
    if (model == null) return null;
    return CitationMapper.toDomain(model);
  }

  @override
  Future<List<Citation>> getByUuids(List<String> uuids) async {
    // Order- and multiplicity-preserving: for each requested UUID (in
    // order, including repeats), look up the citation individually and
    // append it if found; omit silently if not found. A bulk/batch query
    // is not used here because it would not preserve input order or
    // multiplicity without additional post-processing — this explicit
    // per-UUID approach was the clarified contract from Task A.3A.
    final result = <Citation>[];
    for (final uuid in uuids) {
      final model =
          await _isar.citationModels.where().uuidEqualTo(uuid).findFirst();
      if (model != null) {
        result.add(CitationMapper.toDomain(model));
      }
    }
    return result;
  }
}
