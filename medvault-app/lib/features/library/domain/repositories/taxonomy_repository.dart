import '../entities/taxonomy_node.dart';

/// Repository boundary for taxonomy tree nodes.
///
/// Exposes and accepts only the domain [TaxonomyNode] type; no Isar
/// types cross this boundary.
abstract class TaxonomyRepository {
  Future<void> save(TaxonomyNode node);
  Future<void> deleteByUuid(String uuid);

  Future<TaxonomyNode?> getByUuid(String uuid);

  Future<List<TaxonomyNode>> getChildren(String parentUuid);

  /// Returns all taxonomy nodes for library-wide filtering.
  Future<List<TaxonomyNode>> getAll();
}
