import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/bootstrap.dart';
import '../../features/library/data/repositories/isar_taxonomy_repository.dart';
import '../../features/library/domain/repositories/taxonomy_repository.dart';

part 'injector.g.dart';

/// Provides the application's single Isar database instance.
@Riverpod(keepAlive: true)
Future<Isar> appDatabase(AppDatabaseRef ref) async {
  return bootstrap();
}

/// Provides the taxonomy repository backed by the application's Isar database.
@riverpod
Future<TaxonomyRepository> taxonomyRepository(TaxonomyRepositoryRef ref) async {
  final isar = await ref.watch(appDatabaseProvider.future);
  return IsarTaxonomyRepository(isar);
}
