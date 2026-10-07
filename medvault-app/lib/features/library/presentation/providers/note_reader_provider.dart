import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injector.dart';
import '../../domain/services/dto/note_with_citations.dart';

part 'note_reader_provider.g.dart';

/// Loads a note together with its citations and records the note as viewed.
@riverpod
Future<NoteWithCitations?> noteReader(
  NoteReaderRef ref,
  String noteUuid,
) async {
  final libraryService = await ref.watch(libraryServiceProvider.future);

  final noteWithCitations =
      await libraryService.getNoteWithCitations(noteUuid);

  if (noteWithCitations != null) {
    await libraryService.recordNoteViewed(noteUuid);
  }

  return noteWithCitations;
}
