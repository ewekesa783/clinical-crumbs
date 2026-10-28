import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injector.dart';
import '../../../library/domain/services/library_service.dart';

part 'recent_history_provider.g.dart';

/// Loads all retained note and PDF history entries, newest first.
@riverpod
Future<List<RecentLearningResource>> recentHistory(
  RecentHistoryRef ref,
) async {
  final libraryService = await ref.watch(libraryServiceProvider.future);
  return libraryService.getRecentlyViewedResources(limit: null);
}
