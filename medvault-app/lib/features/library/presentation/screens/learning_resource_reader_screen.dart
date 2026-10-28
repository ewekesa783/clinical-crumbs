import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/spacing_tokens.dart';
import '../providers/learning_resource_reader_provider.dart';
import '../../domain/entities/learning_resource.dart';
import 'prototype_html_lesson_viewer.dart';
import 'prototype_lesson_renderer.dart';
import 'html_lesson_action_island.dart';
import 'pdf_reader_screen.dart';

/// Loads a resource and selects its reader based on the stored format.
class LearningResourceReaderScreen extends ConsumerWidget {
  const LearningResourceReaderScreen({
    required this.resourceUuid,
    super.key,
  });

  final String resourceUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourceAsync =
        ref.watch(learningResourceReaderProvider(resourceUuid));

    return resourceAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Learning resource')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Learning resource')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insert_drive_file_outlined, size: 40),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Unable to open this learning resource.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'The resource may have been removed or its file is missing or invalid.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      data: (resource) {
        if (resource.format == LearningResourceFormat.htmlLesson) {
          return Scaffold(
            appBar: AppBar(title: Text(resource.title)),
            body: HtmlLessonActionIsland(
              resourceUuid: resourceUuid,
              title: resource.title,
              filePath: resource.filePath,
              child: resource.lesson != null
                  ? PrototypeLessonRenderer(
                      lesson: resource.lesson!,
                      resourceUuid: resourceUuid,
                      assets: resource.assets,
                      onChooseAnother: () =>
                          Navigator.of(context).maybePop(),
                    )
                  : PrototypeHtmlLessonViewer(
                      html: resource.html!,
                      resourceUuid: resourceUuid,
                    ),
            ),
          );
        }
        return PdfReaderScreen(
          resourceUuid: resourceUuid,
          title: resource.title,
          filePath: resource.filePath,
        );
      },
    );
  }
}
