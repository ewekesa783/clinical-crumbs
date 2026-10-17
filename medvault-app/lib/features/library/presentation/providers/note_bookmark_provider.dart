import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injector.dart';
import '../../../home/presentation/providers/home_dashboard_provider.dart';

part 'note_bookmark_provider.g.dart';

/// Loads and manages the bookmark state for a single note.
@riverpod
class NoteBookmark extends _$NoteBookmark {
  @override
  Future<bool> build(String noteUuid) async {
    final libraryService = await ref.watch(libraryServiceProvider.future);
    return libraryService.isNoteBookmarked(noteUuid);
  }

  Future<void> toggle() async {
    final libraryService = await ref.read(libraryServiceProvider.future);
    final currentlyBookmarked = state.valueOrNull ??
        await libraryService.isNoteBookmarked(noteUuid);

    state = const AsyncLoading();

    try {
      if (currentlyBookmarked) {
        await libraryService.unbookmarkNote(noteUuid);
      } else {
        await libraryService.bookmarkNote(noteUuid);
      }

      state = AsyncData(!currentlyBookmarked);
      ref.invalidate(homeDashboardProvider);
    } catch (_) {
      state = AsyncData(currentlyBookmarked);
      rethrow;
    }
  }
}
