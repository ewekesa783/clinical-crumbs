import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injector.dart';

part 'note_bookmark_provider.g.dart';

/// Loads and manages the bookmark state for a single note.
@riverpod
class NoteBookmark extends _$NoteBookmark {
  @override
  Future<bool> build(String noteUuid) async {
    final libraryService = await ref.watch(libraryServiceProvider.future);
    return libraryService.isNoteBookmarked(noteUuid);
  }

  Future<void> bookmark() async {
    final libraryService = await ref.watch(libraryServiceProvider.future);

    await libraryService.bookmarkNote(noteUuid);

    state = const AsyncData(true);
  }
}
