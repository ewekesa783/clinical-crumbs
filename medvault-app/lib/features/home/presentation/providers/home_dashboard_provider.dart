import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injector.dart';
import '../../../library/domain/entities/note.dart';
import '../../../library/domain/services/library_service.dart';

part 'home_dashboard_provider.g.dart';

class HomeDashboardData {
  const HomeDashboardData({
    required this.recentResources,
    required this.bookmarkedNotes,
    required this.bookmarkedResources,
  });

  final List<RecentLearningResource> recentResources;
  final List<Note> bookmarkedNotes;
  final List<BookmarkedLearningResource> bookmarkedResources;
}

@riverpod
Future<HomeDashboardData> homeDashboard(HomeDashboardRef ref) async {
  final libraryService = await ref.watch(libraryServiceProvider.future);

  final recentResources = await libraryService.getRecentlyViewedResources(
    limit: 5,
  );
  final bookmarkedNotes = await libraryService.getBookmarkedNotes(limit: 5);
  final bookmarkedResources =
      await libraryService.getBookmarkedResources(limit: 5);

  return HomeDashboardData(
    recentResources: recentResources,
    bookmarkedNotes: bookmarkedNotes,
    bookmarkedResources: bookmarkedResources,
  );
}
