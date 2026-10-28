import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injector.dart';
import '../../../home/presentation/providers/home_dashboard_provider.dart';
import '../../../home/presentation/providers/recent_history_provider.dart';

/// Fixed actions displayed above a scrollable HTML lesson.
class HtmlLessonActionIsland extends ConsumerStatefulWidget {
  const HtmlLessonActionIsland({
    required this.resourceUuid,
    required this.title,
    required this.filePath,
    required this.child,
    super.key,
  });

  final String resourceUuid;
  final String title;
  final String filePath;
  final Widget child;

  @override
  ConsumerState<HtmlLessonActionIsland> createState() =>
      _HtmlLessonActionIslandState();
}

class _HtmlLessonActionIslandState
    extends ConsumerState<HtmlLessonActionIsland> {
  bool _isBookmarked = false;
  bool _bookmarkStateLoaded = false;
  bool _bookmarkActionRunning = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarkState();
  }

  Future<void> _loadBookmarkState() async {
    try {
      final service = await ref.read(libraryServiceProvider.future);
      final bookmarked = await service.isLearningResourceBookmarked(
        widget.resourceUuid,
      );
      if (!mounted) return;
      setState(() {
        _isBookmarked = bookmarked;
        _bookmarkStateLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _bookmarkStateLoaded = true);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkActionRunning || !_bookmarkStateLoaded) return;

    setState(() => _bookmarkActionRunning = true);
    try {
      final service = await ref.read(libraryServiceProvider.future);

      if (_isBookmarked) {
        await service.unbookmarkResource(widget.resourceUuid);
      } else {
        await service.bookmarkLearningResource(widget.resourceUuid);
      }

      if (!mounted) return;
      setState(() {
        _isBookmarked = !_isBookmarked;
        _bookmarkActionRunning = false;
      });

      ref.invalidate(homeDashboardProvider);
      ref.invalidate(recentHistoryProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked ? 'Lesson bookmarked' : 'Lesson bookmark removed',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _bookmarkActionRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update this bookmark.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 3),
            child: Material(
              color: theme.colorScheme.surface,
              elevation: 1,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: _isBookmarked
                          ? 'Remove bookmark'
                          : 'Bookmark lesson',
                      onPressed: _bookmarkActionRunning ||
                              !_bookmarkStateLoaded
                          ? null
                          : _toggleBookmark,
                      icon: _bookmarkActionRunning ||
                              !_bookmarkStateLoaded
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                            ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: 'Lesson sharing links are not available yet',
                      onPressed: null,
                      disabledColor: theme.colorScheme.onSurface.withOpacity(0.45),
                      icon: const Icon(Icons.share_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
