import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injector.dart';
import '../../../library/domain/entities/note.dart';

part 'home_dashboard_provider.g.dart';

class HomeDashboardData {
  const HomeDashboardData({
    required this.recentNotes,
    required this.bookmarkedNotes,
  });

  final List<Note> recentNotes;
  final List<Note> bookmarkedNotes;
}

@riverpod
Future<HomeDashboardData> homeDashboard(HomeDashboardRef ref) async {
  final libraryService = await ref.watch(libraryServiceProvider.future);

  final results = await Future.wait([
    libraryService.getRecentlyViewedNotes(limit: 5),
    libraryService.getBookmarkedNotes(limit: 5),
  ]);

  return HomeDashboardData(
    recentNotes: results[0],
    bookmarkedNotes: results[1],
  );
}
