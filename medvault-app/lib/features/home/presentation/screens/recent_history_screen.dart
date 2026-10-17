import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../providers/recent_history_provider.dart';

class RecentHistoryScreen extends ConsumerWidget {
  const RecentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(recentHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Recent history')),
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
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history, size: 44),
                    const SizedBox(height: 12),
                    Text('No recent history', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('Notes you open will appear here.'),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.history),
                  ),
                  title: Text(note.title),
                  subtitle: Text(_formatMode(note.mode.name)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => NoteReaderRoute(noteUuid: note.uuid).push(context),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatMode(String mode) {
    return mode
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        )
        .replaceFirstMapped(
          RegExp(r'^[a-z]'),
          (match) => match[0]!.toUpperCase(),
        );
  }
}
