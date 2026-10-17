import 'package:isar/isar.dart';

import '../../domain/entities/taxonomy_node.dart';
import '../../domain/repositories/taxonomy_repository.dart';
import '../models/taxonomy_node_mapper.dart';
import '../models/taxonomy_node_model.dart';

/// Isar-backed implementation of [TaxonomyRepository].
///
/// KNOWN GAP (preserved intentionally — do not "fix" without an explicit
/// task authorizing it): every query in this repository uses Isar's
/// `.filter()` (an unindexed, full-collection scan) rather than `.where()`
/// (an indexed lookup), despite `uuid`, `parentUuid`, `path`, and `depth`
/// all being indexed fields on [TaxonomyNodeModel]. This is a real
/// performance/correctness distinction per Data Model Specification §11
/// and Engineering Implementation Specification §26. Contrast with
/// IsarNoteRepository, which correctly uses `.where()`.
class IsarTaxonomyRepository implements TaxonomyRepository {
  IsarTaxonomyRepository(this._isar);

  final Isar _isar;

  @override
  Future<void> save(TaxonomyNode node) async {
    final model = TaxonomyNodeMapper.toModel(node);

    final siblingWithSameSlug = await _isar.taxonomyNodeModels
        .filter()
        .parentUuidEqualTo(model.parentUuid)
        .slugEqualTo(model.slug)
        .findFirst();

    if (siblingWithSameSlug != null && siblingWithSameSlug.uuid != model.uuid) {
      throw StateError(
        'A sibling taxonomy node with slug "${model.slug}" already exists '
        'under parent "${model.parentUuid}".',
      );
    }

    final existing = await _isar.taxonomyNodeModels
        .filter()
        .uuidEqualTo(model.uuid)
        .findFirst();
    if (existing != null) {
      model.id = existing.id;
    }

    await _isar.writeTxn(() async {
      await _isar.taxonomyNodeModels.put(model);
    });
  }

  @override
  Future<TaxonomyNode?> getByUuid(String uuid) async {
    final model =
        await _isar.taxonomyNodeModels.filter().uuidEqualTo(uuid).findFirst();
    if (model == null) return null;
    return TaxonomyNodeMapper.toDomain(model);
  }

  @override
  Future<List<TaxonomyNode>> getChildren(String parentUuid) async {
    final models = await _isar.taxonomyNodeModels
        .filter()
        .parentUuidEqualTo(parentUuid)
        .findAll();
    return models.map(TaxonomyNodeMapper.toDomain).toList();
  }

  @override
  Future<List<TaxonomyNode>> getAll() async {
    final models = await _isar.taxonomyNodeModels.where().findAll();
    return models.map(TaxonomyNodeMapper.toDomain).toList();
  }
}
