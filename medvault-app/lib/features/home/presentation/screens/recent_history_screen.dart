import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/di/injector.dart';
import '../providers/home_dashboard_provider.dart';
import '../providers/recent_history_provider.dart';

Future<void> _confirmAndClearHistory(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Clear recent history?'),
      content: const Text(
        'This removes all recent-history entries. Your notes, PDFs, bookmarks, and saved reading positions will remain unchanged.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Clear history'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final service = await ref.read(libraryServiceProvider.future);
  await service.clearHistory();
  ref.invalidate(recentHistoryProvider);
  ref.invalidate(homeDashboardProvider);
}

class RecentHistoryScreen extends ConsumerWidget {
  const RecentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(recentHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent history'),
        actions: [
          if (history.valueOrNull?.isNotEmpty ?? false)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmAndClearHistory(context, ref),
            ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, size: 40),
                const SizedBox(height: 12),
                const Text('Could not load recent history'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => ref.invalidate(recentHistoryProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (resources) {
          if (resources.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history, size: 44),
                    const SizedBox(height: 12),
                    Text('No recent history',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('Notes and PDFs you open will appear here.'),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: resources.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final resource = resources[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      resource.isPdf
                          ? Icons.picture_as_pdf_outlined
                          : resource.isHtmlLesson
                              ? Icons.article_outlined
                              : Icons.history,
                    ),
                  ),
                  title: Text(resource.title),
                  subtitle: Text(
                    resource.isPdf
                        ? 'PDF document'
                        : resource.isHtmlLesson
                            ? 'HTML lesson'
                            : 'Note',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Remove from history',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final service =
                              await ref.read(libraryServiceProvider.future);
                          await service.removeHistoryEntry(resource.uuid);
                          ref.invalidate(recentHistoryProvider);
                          ref.invalidate(homeDashboardProvider);
                        },
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    if (resource.isPdf || resource.isHtmlLesson) {
                      LearningResourceReaderRoute(
                        resourceUuid: resource.uuid,
                      ).push(context);
                    } else {
                      NoteReaderRoute(noteUuid: resource.uuid).push(context);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
