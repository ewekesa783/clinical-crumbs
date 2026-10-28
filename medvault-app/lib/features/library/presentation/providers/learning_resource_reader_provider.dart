import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/topic_packages/prototype_html_lesson_archive_reader.dart';
import '../../data/topic_packages/prototype_lesson_archive_reader.dart';
import '../../domain/entities/learning_resource.dart';

import '../../../../core/di/injector.dart';
import '../../../home/presentation/providers/home_dashboard_provider.dart';
import '../../../home/presentation/providers/recent_history_provider.dart';

part 'learning_resource_reader_provider.g.dart';

class LearningResourceReaderData {
  const LearningResourceReaderData({
    required this.title,
    required this.format,
    required this.filePath,
    this.html,
    this.lesson,
    this.assets = const {},
  });

  final String title;
  final LearningResourceFormat format;
  final String filePath;
  final String? html;
  final Map<String, dynamic>? lesson;
  final Map<String, Uint8List> assets;
}

@riverpod
Future<LearningResourceReaderData> learningResourceReader(
  LearningResourceReaderRef ref,
  String resourceUuid,
) async {
  final repository = await ref.watch(learningResourceRepositoryProvider.future);
  final resource = await repository.getByUuid(resourceUuid);

  if (resource == null) {
    throw StateError('No learning resource found for uuid "$resourceUuid".');
  }

  final libraryService = await ref.watch(libraryServiceProvider.future);
  await libraryService.recordResourceViewed(resourceUuid);
  ref.invalidate(homeDashboardProvider);
  ref.invalidate(recentHistoryProvider);

  final storage = ref.watch(learningResourceFileStorageProvider);

  if (resource.format == LearningResourceFormat.htmlLesson) {
    final file = await storage.resolveHtmlLessonPackage(
      resource.relativeFilePath,
    );
    final bytes = await file.readAsBytes();

    try {
      final archive = const PrototypeLessonArchiveReader().read(bytes);
      return LearningResourceReaderData(
        title: resource.title,
        format: resource.format,
        filePath: file.path,
        lesson: archive.lesson,
        assets: archive.assets,
      );
    } on FormatException catch (error) {
      if (error.message !=
          'The ZIP must contain lesson.json or one lesson JSON under content/.') {
        rethrow;
      }
    }

    final htmlArchive =
        const PrototypeHtmlLessonArchiveReader().read(bytes);

    return LearningResourceReaderData(
      title: resource.title,
      format: resource.format,
      filePath: file.path,
      html: htmlArchive.html,
    );
  }

  final file = await storage.resolvePdf(resource.relativeFilePath);

  return LearningResourceReaderData(
    title: resource.title,
    format: resource.format,
    filePath: file.path,
  );
}
