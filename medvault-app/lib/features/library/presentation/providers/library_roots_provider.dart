import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injector.dart';
import '../../data/models/taxonomy_node_mapper.dart';
import '../../data/models/taxonomy_node_model.dart';
import '../../domain/entities/taxonomy_node.dart';

part 'library_roots_provider.g.dart';

/// Loads the root nodes of the Library taxonomy.
///
/// Root nodes are represented by a null [TaxonomyNode.parentUuid].
/// The query uses the existing Isar index on parentUuid.
@riverpod
Future<List<TaxonomyNode>> libraryRoots(LibraryRootsRef ref) async {
  final isar = await ref.watch(appDatabaseProvider.future);

  final models = await isar.taxonomyNodeModels.where().findAll();

  final nodes = models
      .map(TaxonomyNodeMapper.toDomain)
      .where((node) => node.parentUuid == null)
      .toList();
  nodes.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return nodes;
}
