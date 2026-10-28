import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/sync_metadata_model.dart';
import '../../../../core/storage/learning_resource_file_storage.dart';
import '../models/bookmark_model.dart';
import '../models/citation_model.dart';
import '../models/history_model.dart';
import '../models/learning_resource_model.dart';
import '../models/note_model.dart';
import '../models/taxonomy_node_model.dart';
import 'curriculum_pack_exporter.dart';

/// Exports portable curriculum content and a recoverable local-state snapshot.
///
/// Exporting is read-only. Device identity and unrelated preferences are
/// intentionally excluded.
class FullLibraryBackupExporter {
  FullLibraryBackupExporter({
    required Isar isar,
    required LearningResourceFileStorage fileStorage,
    String Function()? generatePackUuid,
    SharedPreferences? preferences,
    DateTime Function()? clock,
  })  : _isar = isar,
        _fileStorage = fileStorage,
        _generatePackUuid = generatePackUuid,
        _preferences = preferences,
        _clock = clock ?? DateTime.now;

  final Isar _isar;
  final LearningResourceFileStorage _fileStorage;
  final String Function()? _generatePackUuid;
  final SharedPreferences? _preferences;
  final DateTime Function() _clock;

  static const int formatVersion = 1;

  Future<Uint8List> exportZip() async {
    try {
      final pack = await CurriculumPackExporter(
        isar: _isar,
        generatePackUuid: _generatePackUuid,
      ).exportPack();

      final payloads = <String, List<int>>{
        'curriculum-pack.json': _jsonBytes(pack.toJson()),
      };

      final taxonomy = await _isar.taxonomyNodeModels.where().findAll()
        ..sort((a, b) => a.uuid.compareTo(b.uuid));
      final notes = await _isar.noteModels.where().findAll()
        ..sort((a, b) => a.uuid.compareTo(b.uuid));
      final citations = await _isar.citationModels.where().findAll()
        ..sort((a, b) => a.uuid.compareTo(b.uuid));
      final bookmarks = await _isar.bookmarkModels.where().findAll()
        ..sort((a, b) => a.uuid.compareTo(b.uuid));
      final history = await _isar.historyModels.where().findAll()
        ..sort((a, b) => a.uuid.compareTo(b.uuid));
      final resources = await _isar.learningResourceModels.where().findAll()
        ..sort((a, b) => a.uuid.compareTo(b.uuid));

      payloads['database/taxonomy.json'] = _jsonBytes(
        taxonomy.map(_taxonomyJson).toList(),
      );
      payloads['database/notes.json'] = _jsonBytes(
        notes.map(_noteJson).toList(),
      );
      payloads['database/citations.json'] = _jsonBytes(
        citations.map(_citationJson).toList(),
      );
      payloads['personal-data/bookmarks.json'] = _jsonBytes(
        bookmarks.map(_bookmarkJson).toList(),
      );
      payloads['personal-data/history.json'] = _jsonBytes(
        history.map(_historyJson).toList(),
      );

      final preferences = _preferences ?? await SharedPreferences.getInstance();
      payloads['personal-data/preferences.json'] =
          _jsonBytes(_selectedPreferences(preferences));

      final resourceMetadata = <Map<String, Object?>>[];

      for (final resource in resources) {
        final pathSegments =
            resource.relativeFilePath.split(RegExp(r'[/\\]'));
        final isHtmlLesson = pathSegments.length == 3 &&
            pathSegments[0] == 'learning_resources' &&
            pathSegments[1] == 'html_lessons';

        final file = isHtmlLesson
            ? await _fileStorage.resolveHtmlLessonPackage(
                resource.relativeFilePath,
              )
            : await _fileStorage.resolvePdf(resource.relativeFilePath);
        final resourceBytes = await file.readAsBytes();

        if (resourceBytes.length != resource.fileSizeBytes) {
          final kind = isHtmlLesson ? 'HTML lesson package' : 'PDF';
          throw FullLibraryBackupExportException(
            'The $kind "${resource.originalFileName}" has a size mismatch. '
            'No complete backup was created.',
          );
        }

        final format = isHtmlLesson ? 'htmlLesson' : 'pdf';
        final archivePath = isHtmlLesson
            ? 'resources/html_lessons/${resource.uuid}.zip'
            : 'resources/pdfs/${resource.uuid}.pdf';
        payloads[archivePath] = resourceBytes;

        resourceMetadata.add({
          'uuid': resource.uuid,
          'topicUuid': resource.topicUuid,
          'title': resource.title,
          'originalFileName': resource.originalFileName,
          'fileSizeBytes': resource.fileSizeBytes,
          'importedAt': resource.importedAt.toIso8601String(),
          'format': format,
          'archivePath': archivePath,
        });
      }

      payloads['resources/metadata.json'] = _jsonBytes(resourceMetadata);

      // The manifest covers every payload, but not itself.
      final manifest = <String, Object?>{
        'formatVersion': formatVersion,
        'createdAt': _clock().toUtc().toIso8601String(),
        'payloads': {
          for (final entry in payloads.entries)
            entry.key: {
              'sha256': sha256.convert(entry.value).toString(),
              'sizeBytes': entry.value.length,
            },
        },
      };

      final archive = Archive();
      for (final entry in payloads.entries) {
        archive.addFile(ArchiveFile.bytes(entry.key, entry.value));
      }
      archive.addFile(
        ArchiveFile.bytes(
          'backup-manifest.json',
          _jsonBytes(manifest),
        ),
      );

      return ZipEncoder().encodeBytes(archive);
    } on CurriculumPackExportException {
      rethrow;
    } on FullLibraryBackupExportException {
      rethrow;
    } on FileSystemException catch (error) {
      throw FullLibraryBackupExportException(
        'A stored PDF could not be read. Check that your imported files '
        'are present and accessible. Details: ${error.message}',
      );
    } catch (error) {
      throw FullLibraryBackupExportException(
        'Could not create the full-library ZIP backup. Details: $error',
      );
    }
  }

  static List<int> _jsonBytes(Object? value) =>
      utf8.encode(const JsonEncoder.withIndent('  ').convert(value));

  static Map<String, Object?> _syncJson(SyncMetadataModel sync) => {
        'remoteId': sync.remoteId,
        'lastModifiedLocal': sync.lastModifiedLocal.toIso8601String(),
        'lastSyncedAt': sync.lastSyncedAt?.toIso8601String(),
        'isDirty': sync.isDirty,
        'isDeleted': sync.isDeleted,
        'deviceId': sync.deviceId,
        'syncRevision': sync.syncRevision,
      };

  static Map<String, Object?> _taxonomyJson(TaxonomyNodeModel node) => {
        'uuid': node.uuid,
        'parentUuid': node.parentUuid,
        'path': node.path,
        'depth': node.depth,
        'nodeType': node.nodeType.name,
        'title': node.title,
        'slug': node.slug,
        'shortDescription': node.shortDescription,
        'iconKey': node.iconKey,
        'sortOrder': node.sortOrder,
        'noteCount': node.noteCount,
        'curriculumPackUuid': node.curriculumPackUuid,
        'curriculumPackVersion': node.curriculumPackVersion,
        'isUserCreated': node.isUserCreated,
        'createdAt': node.createdAt.toIso8601String(),
        'updatedAt': node.updatedAt.toIso8601String(),
        'sync': _syncJson(node.sync),
      };

  static Map<String, Object?> _noteJson(NoteModel note) => {
        'uuid': note.uuid,
        'topicUuid': note.topicUuid,
        'mode': note.mode.name,
        'title': note.title,
        'bodyMarkdown': note.bodyMarkdown,
        'plainTextExtract': note.plainTextExtract,
        'tags': note.tags,
        'citationOrder': note.citationOrder,
        'isPinned': note.isPinned,
        'createdAt': note.createdAt.toIso8601String(),
        'updatedAt': note.updatedAt.toIso8601String(),
        'sync': _syncJson(note.sync),
      };

  static Map<String, Object?> _citationJson(CitationModel citation) => {
        'uuid': citation.uuid,
        'sourceType': citation.sourceType.name,
        'title': citation.title,
        'authors': citation.authors,
        'publicationYear': citation.publicationYear,
        'pageReference': citation.pageReference,
        'url': citation.url,
        'createdAt': citation.createdAt.toIso8601String(),
        'updatedAt': citation.updatedAt.toIso8601String(),
        'sync': _syncJson(citation.sync),
      };

  static Map<String, Object?> _bookmarkJson(BookmarkModel bookmark) => {
        'uuid': bookmark.uuid,
        'noteUuid': bookmark.noteUuid,
        'label': bookmark.label,
        'createdAt': bookmark.createdAt.toIso8601String(),
        'sync': _syncJson(bookmark.sync),
      };

  static Map<String, Object?> _historyJson(HistoryModel entry) => {
        'uuid': entry.uuid,
        'noteUuid': entry.noteUuid,
        'viewedAt': entry.viewedAt.toIso8601String(),
        'sync': _syncJson(entry.sync),
      };

  static Map<String, Object?> _selectedPreferences(
    SharedPreferences preferences,
  ) {
    final values = <String, Object?>{};
    for (final key in preferences.getKeys()) {
      final isSelectedKey = key == 'appearance.themePreference' ||
          key == 'reading.textSize' ||
          key == 'pdf_reader_continuous_mode' ||
          key == 'clinical_crumbs_starter_content_ledger_v1' ||
          key.startsWith('pdf_reader_last_page_') ||
          key.startsWith('reader.scrollOffset.');

      if (isSelectedKey) {
        values[key] = preferences.get(key);
      }
    }
    return {'values': values};
  }
}

class FullLibraryBackupExportException implements Exception {
  const FullLibraryBackupExportException(this.message);

  final String message;

  @override
  String toString() => 'FullLibraryBackupExportException: $message';
}
