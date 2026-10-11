import 'package:medvault_app/core/di/injector.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
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
