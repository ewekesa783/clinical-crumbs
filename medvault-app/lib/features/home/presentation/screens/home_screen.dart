import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/di/injector.dart';
import '../../../library/domain/services/library_service.dart';
import '../providers/home_dashboard_provider.dart';

String _recentNoteSubtitle(RecentLearningResource resource) {
  return 'Note';
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showBookmarks = false;

  void _openResource(BuildContext context, RecentLearningResource resource) {
    if (resource.isPdf || resource.isHtmlLesson) {
      LearningResourceReaderRoute(resourceUuid: resource.uuid).push(context);
    } else {
      NoteReaderRoute(noteUuid: resource.uuid).push(context);
    }
  }

  Future<void> _removeBookmark(String resourceUuid) async {
    final service = await ref.read(libraryServiceProvider.future);
    await service.unbookmarkResource(resourceUuid);
    ref.invalidate(homeDashboardProvider);
  }

  Future<void> _confirmAndClearBookmarks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all bookmarks?'),
        content: const Text(
          'This removes all saved bookmarks. Your notes and PDFs will remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final service = await ref.read(libraryServiceProvider.future);
    await service.clearAllBookmarks();
    ref.invalidate(homeDashboardProvider);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(homeDashboardProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 24,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeDashboardProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 2, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 2,
                        color: const Color(0xFF6EAAA4),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'YOUR LEARNING SPACE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF83B8B1),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome back',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.7,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Pick up where you left off.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            dashboard.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => _DashboardError(
                onRetry: () => ref.invalidate(homeDashboardProvider),
              ),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.recentResources.isNotEmpty)
                    _ResumeReadingCard(
                      title: data.recentResources.first.title,
                      subtitle: data.recentResources.first.isPdf
                          ? 'PDF document'
                          : 'Note',
                      isPdf: data.recentResources.first.isPdf,
                      onTap: () => _openResource(
                        context,
                        data.recentResources.first,
                      ),
                    )
                  else
                    _ResumeEmptyCard(
                      onTap: () => const LibraryRoute().go(context),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _DashboardActionCard(
                          icon: Icons.local_library_outlined,
                          title: 'Browse Library',
                          subtitle: 'Explore your notes',
                          onTap: () => const LibraryRoute().go(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardActionCard(
                          icon: Icons.bookmark_outline,
                          title: 'Bookmarks',
                          subtitle: data.bookmarkedResources.isEmpty
                              ? 'Your saved items'
                              : '${data.bookmarkedResources.length} saved item${data.bookmarkedResources.length == 1 ? '' : 's'}',
                          trailingIcon: _showBookmarks
                              ? Icons.expand_less
                              : Icons.expand_more,
                          onTap: () {
                            setState(() {
                              _showBookmarks = !_showBookmarks;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_showBookmarks) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Column(
                        children: [
                          if (data.bookmarkedResources.isEmpty)
                            const _EmptySection(
                              icon: Icons.bookmark_border,
                              title: 'No bookmarks yet',
                              message:
                                  'Bookmark notes and PDFs to find them here quickly.',
                            )
                          else ...[
                            ...data.bookmarkedResources.map(
                              (resource) => _NoteCard(
                                title: resource.title,
                                subtitle: resource.subtitle,
                                icon: resource.isPdf
                                    ? Icons.picture_as_pdf_outlined
                                    : resource.isHtmlLesson
                                        ? Icons.article_outlined
                                        : Icons.bookmark_outline,
                                onTap: () {
                                  if (resource.isPdf || resource.isHtmlLesson) {
                                    LearningResourceReaderRoute(
                                      resourceUuid: resource.uuid,
                                    ).push(context);
                                  } else {
                                    NoteReaderRoute(
                                      noteUuid: resource.uuid,
                                    ).push(context);
                                  }
                                },
                                onRemove: () => _removeBookmark(resource.uuid),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _confirmAndClearBookmarks,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Clear all bookmarks'),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () =>
                                    const LibraryRoute().go(context),
                                icon: const Icon(Icons.library_books_outlined),
                                label: const Text('Open Library'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 0,
                    color: Colors.transparent,
                    margin: EdgeInsets.zero,
                    shape: Border(
                      top: BorderSide(color: colors.outlineVariant),
                      bottom: BorderSide(color: colors.outlineVariant),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.history),
                      title: Text(
                        'Continue studying',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        data.recentResources.isEmpty
                            ? 'Your recently viewed notes and PDFs'
                            : data.recentResources.length == 1
                                ? 'Your latest resource is above'
                                : '${data.recentResources.length - 1} other recently opened resources',
                      ),
                      initiallyExpanded: false,
                      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                      children: [
                        if (data.recentResources.isEmpty)
                          const _EmptySection(
                            icon: Icons.menu_book_outlined,
                            title: 'Nothing here yet',
                            message:
                                'Open a note or PDF from your Library and it will appear here.',
                          )
                        else if (data.recentResources.length == 1)
                          const _EmptySection(
                            icon: Icons.menu_book_outlined,
                            title: 'You’re all caught up',
                            message:
                                'Open more notes or PDFs and they’ll appear here.',
                          )
                        else ...[
                          ...data.recentResources.skip(1).map(
                                (resource) => _NoteCard(
                                  title: resource.title,
                                  subtitle: resource.isPdf
                                      ? 'PDF document'
                                      : resource.isHtmlLesson
                                          ? 'HTML lesson'
                                          : _recentNoteSubtitle(resource),
                                  icon: resource.isPdf
                                      ? Icons.picture_as_pdf_outlined
                                      : resource.isHtmlLesson
                                          ? Icons.article_outlined
                                          : Icons.history,
                                  onTap: () => _openResource(context, resource),
                                ),
                              ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => context.push('/history'),
                              icon: const Icon(Icons.list_alt),
                              label: const Text('View all history'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeReadingCard extends StatelessWidget {
  const _ResumeReadingCard({
    required this.title,
    required this.subtitle,
    required this.isPdf,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isPdf;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const foreground = Colors.white;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0xFF243B6B),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.play_circle_outline, color: foreground, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'RESUME READING',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: foreground.withOpacity(0.85),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                    ),
                  ),
                  Icon(
                    isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.menu_book_outlined,
                    color: foreground.withOpacity(0.8),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground.withOpacity(0.8),
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Continue reading',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward, color: foreground, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeEmptyCard extends StatelessWidget {
  const _ResumeEmptyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.primaryContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 34,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready for your next session?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Browse your Library to get started.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: colors.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingIcon = Icons.arrow_forward,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF83B8B1), size: 24),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  trailingIcon,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
          child: Row(
            children: [
              const Icon(
                Icons.local_library_outlined,
                color: Color(0xFF83B8B1),
                size: 23,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse your Library',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Search and explore your imported notes'),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 22,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onSeeAll,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF83B8B1),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Library'),
          ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.onRemove,
    this.featured = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const teal = Color(0xFF4DB6AC);

    return Card(
      color: featured && theme.brightness == Brightness.dark
          ? const Color(0xFF1A2524)
          : Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: featured ? 7 : 1,
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: teal.withOpacity(0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF83B8B1), size: 19),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(_formatMode(subtitle)),
        trailing: onRemove == null
            ? const Icon(Icons.chevron_right)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Remove saved bookmark',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
        onTap: onTap,
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

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: colors.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36),
          const SizedBox(height: 12),
          const Text('Could not load your dashboard'),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
