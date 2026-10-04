import '../entities/taxonomy_node.dart';
import '../repositories/taxonomy_repository.dart';

/// Coordinates TaxonomyRepository lookups for navigation concerns that
/// require walking the tree.
///
/// FINAL SHAPE (MV-IP-002 Task A.2A correction): this service exposes
/// ONLY [getBreadcrumbPath]. An earlier draft also included a
/// `getSiblings()` method; it was REMOVED after applying the project's
/// service-layer test ("does this perform real multi-repository
/// coordination or data-dependent control flow that no single
/// repository call could express?") — `getSiblings()` was just
/// `taxonomyRepository.getChildren(node.parentUuid)`, a single
/// repository call with no additional coordination, so it belonged on
/// the repository (already available as
/// `TaxonomyRepository.getChildren`), not on this service. Do not
/// reintroduce it without an explicit task authorizing new
/// service-layer scope.
class TaxonomyNavigationService {
  TaxonomyNavigationService({required TaxonomyRepository taxonomyRepository})
      : _taxonomyRepository = taxonomyRepository;

  final TaxonomyRepository _taxonomyRepository;

  /// Returns the chain of ancestor nodes from the root down to (and
  /// including) [nodeUuid], by walking `parentUuid` links.
  ///
  /// Genuine service-layer work: requires repeatedly querying the
  /// repository and following each result's `parentUuid` until reaching
  /// a root (`parentUuid == null`) — data-dependent control flow that no
  /// single repository call could express.
  Future<List<TaxonomyNode>> getBreadcrumbPath(String nodeUuid) async {
    final path = <TaxonomyNode>[];

    String? currentUuid = nodeUuid;
    while (currentUuid != null) {
      final node = await _taxonomyRepository.getByUuid(currentUuid);
      if (node == null) {
        throw StateError('No taxonomy node found for uuid "$currentUuid".');
      }
      path.insert(0, node);
      currentUuid = node.parentUuid;
    }

    return path;
  }
}
