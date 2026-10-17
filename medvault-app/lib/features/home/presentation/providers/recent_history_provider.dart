import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injector.dart';
import '../../../library/domain/entities/note.dart';

part 'recent_history_provider.g.dart';

/// Loads all retained history entries, newest first.
@riverpod
Future<List<Note>> recentHistory(RecentHistoryRef ref) async {
  final libraryService = await ref.watch(libraryServiceProvider.future);
  return libraryService.getRecentlyViewedNotes(limit: null);
}
