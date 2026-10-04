import '../entities/taxonomy_node.dart';

/// Repository boundary for taxonomy tree nodes.
///
/// Exposes and accepts only the domain [TaxonomyNode] type; no Isar
/// types cross this boundary.
abstract class TaxonomyRepository {
  Future<void> save(TaxonomyNode node);

  Future<TaxonomyNode?> getByUuid(String uuid);

  Future<List<TaxonomyNode>> getChildren(String parentUuid);
}
