import 'package:medvault_app/core/di/injector.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
import 'package:medvault_app/features/library/domain/entities/learning_resource.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';
import 'package:medvault_app/features/library/presentation/providers/library_roots_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'note_search_provider.g.dart';

@riverpod
Future<List<Note>> noteSearch(
  NoteSearchRef ref,
  String query,
) async {
  final repository = await ref.watch(noteRepositoryProvider.future);
  return repository.search(query);
}

/// Loads all notes so mode and taxonomy filters work without a text query.
@riverpod
Future<List<Note>> allLibraryNotes(AllLibraryNotesRef ref) async {
  final repository = await ref.watch(noteRepositoryProvider.future);
  return repository.getAll();
}

/// Loads imported PDF resources independently so Library tests can override them.
@riverpod
Future<List<LearningResource>> allLearningResources(
  AllLearningResourcesRef ref,
) async {
  final repository = await ref.watch(learningResourceRepositoryProvider.future);
  return repository.getAll();
}

/// Combined results for Library search across notes and imported PDF resources.
class LibrarySearchResults {
  const LibrarySearchResults({
    required this.notes,
    required this.resources,
    required this.taxonomyNodes,
  });

  final List<Note> notes;
  final List<LearningResource> resources;
  final List<TaxonomyNode> taxonomyNodes;
}

/// Searches notes, imported PDFs, and taxonomy nodes across the library.
@riverpod
Future<LibrarySearchResults> librarySearch(
  LibrarySearchRef ref,
  String query,
) async {
  final normalizedQuery = query.trim();
  final lowerQuery = normalizedQuery.toLowerCase();

  final notes = normalizedQuery.length >= 2
      ? await ref.watch(noteSearchProvider(normalizedQuery).future)
      : await ref.watch(allLibraryNotesProvider.future);

  final allResources = await ref.watch(allLearningResourcesProvider.future);
  final resources = lowerQuery.length < 2
      ? allResources
      : allResources.where((resource) {
          return resource.title.toLowerCase().contains(lowerQuery) ||
              resource.originalFileName.toLowerCase().contains(lowerQuery);
        }).toList();

  final allTaxonomyNodes = normalizedQuery.length < 2
      ? <TaxonomyNode>[]
      : await ref.watch(libraryTaxonomyNodesProvider.future);

  final taxonomyNodes = allTaxonomyNodes.where((node) {
    return node.title.toLowerCase().contains(lowerQuery) ||
        node.slug.toLowerCase().contains(lowerQuery) ||
        (node.shortDescription?.toLowerCase().contains(lowerQuery) ?? false);
  }).toList();

  return LibrarySearchResults(
    notes: notes,
    resources: resources,
    taxonomyNodes: taxonomyNodes,
  );
}
