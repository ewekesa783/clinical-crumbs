import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/database/sync_metadata_model.dart';
import '../../domain/entities/citation.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/taxonomy_node.dart';
import '../models/bookmark_model.dart';
import '../models/citation_model.dart';
import '../models/history_model.dart';
import '../models/learning_resource_model.dart';
import '../models/note_model.dart';
import '../models/taxonomy_node_model.dart';
import 'full_library_backup_validator.dart';

/// Decodes a validated full backup into fresh persistence models.
///
/// This class is deliberately preparation-only: it does not write to Isar,
/// preferences, or the filesystem.
class FullLibraryBackupPreparer {
  const FullLibraryBackupPreparer({
    FullLibraryBackupValidator validator = const FullLibraryBackupValidator(),
  }) : _validator = validator;

  final FullLibraryBackupValidator _validator;

  PreparedFullLibraryBackup prepare(Uint8List zipBytes) {
    final backup = _validator.validate(zipBytes);
    final payloads = backup.payloads;

    final taxonomy = _jsonList(payloads, 'database/taxonomy.json');
    final notes = _jsonList(payloads, 'database/notes.json');
    final citations = _jsonList(payloads, 'database/citations.json');
    final bookmarks = _jsonList(payloads, 'personal-data/bookmarks.json');
    final history = _jsonList(payloads, 'personal-data/history.json');
    final resources = _jsonList(payloads, 'resources/metadata.json');

    final taxonomyModels = taxonomy.map((row) {
      return TaxonomyNodeModel()
        ..uuid = _string(row, 'uuid')
        ..parentUuid = _nullableString(row, 'parentUuid')
        ..path = _string(row, 'path')
        ..depth = _int(row, 'depth')
        ..nodeType = NodeType.values.byName(_string(row, 'nodeType'))
        ..title = _string(row, 'title')
        ..slug = _string(row, 'slug')
        ..shortDescription = _nullableString(row, 'shortDescription')
        ..iconKey = _nullableString(row, 'iconKey')
        ..sortOrder = _int(row, 'sortOrder')
        ..noteCount = _int(row, 'noteCount')
        ..curriculumPackUuid = _nullableString(row, 'curriculumPackUuid')
        ..curriculumPackVersion = _nullableInt(row, 'curriculumPackVersion')
        ..isUserCreated = _bool(row, 'isUserCreated')
        ..createdAt = _dateTime(row, 'createdAt')
        ..updatedAt = _dateTime(row, 'updatedAt')
        ..sync = _sync(row['sync']);
    }).toList(growable: false);

    final noteModels = notes.map((row) {
      return NoteModel()
        ..uuid = _string(row, 'uuid')
        ..topicUuid = _string(row, 'topicUuid')
        ..mode = Mode.values.byName(_string(row, 'mode'))
        ..title = _string(row, 'title')
        ..bodyMarkdown = _string(row, 'bodyMarkdown')
        ..plainTextExtract = _nullableString(row, 'plainTextExtract')
        ..tags = _stringList(row, 'tags')
        ..citationOrder = _stringList(row, 'citationOrder')
        ..isPinned = _bool(row, 'isPinned')
        ..createdAt = _dateTime(row, 'createdAt')
        ..updatedAt = _dateTime(row, 'updatedAt')
        ..sync = _sync(row['sync']);
    }).toList(growable: false);

    final citationModels = citations.map((row) {
      return CitationModel()
        ..uuid = _string(row, 'uuid')
        ..sourceType = SourceType.values.byName(_string(row, 'sourceType'))
        ..title = _string(row, 'title')
        ..authors = _nullableString(row, 'authors')
        ..publicationYear = _nullableInt(row, 'publicationYear')
        ..pageReference = _nullableString(row, 'pageReference')
        ..url = _nullableString(row, 'url')
        ..createdAt = _dateTime(row, 'createdAt')
        ..updatedAt = _dateTime(row, 'updatedAt')
        ..sync = _sync(row['sync']);
    }).toList(growable: false);

    final bookmarkModels = bookmarks.map((row) {
      return BookmarkModel()
        ..uuid = _string(row, 'uuid')
        ..noteUuid = _string(row, 'noteUuid')
        ..label = _nullableString(row, 'label')
        ..createdAt = _dateTime(row, 'createdAt')
        ..sync = _sync(row['sync']);
    }).toList(growable: false);

    final historyModels = history.map((row) {
      return HistoryModel()
        ..uuid = _string(row, 'uuid')
        ..noteUuid = _string(row, 'noteUuid')
        ..viewedAt = _dateTime(row, 'viewedAt')
        ..sync = _sync(row['sync']);
    }).toList(growable: false);

    final resourceModels = <LearningResourceModel>[];
    final pdfBytesByUuid = <String, Uint8List>{};
    final resourceBytesByUuid = <String, Uint8List>{};

    for (final row in resources) {
      final uuid = _string(row, 'uuid');
      final archivePath = _string(row, 'archivePath');
      final bytes = payloads[archivePath];

      // Older version-1 backups omit format, which means PDF.
      final format = row['format'] ?? 'pdf';
      if (format is! String ||
          (format != 'pdf' && format != 'htmlLesson')) {
        throw FormatException(
          'The format for resource "$uuid" is not supported.',
        );
      }

      if (bytes == null) {
        throw FormatException(
          'The resource payload for "$uuid" is missing.',
        );
      }

      final isHtmlLesson = format == 'htmlLesson';
      final resource = LearningResourceModel()
        ..uuid = uuid
        ..topicUuid = _string(row, 'topicUuid')
        ..title = _string(row, 'title')
        ..originalFileName = _string(row, 'originalFileName')
        ..relativeFilePath = isHtmlLesson
            ? 'learning_resources/html_lessons/$uuid.zip'
            : 'learning_resources/pdfs/$uuid.pdf'
        ..fileSizeBytes = _int(row, 'fileSizeBytes')
        ..importedAt = _dateTime(row, 'importedAt');

      resourceModels.add(resource);
      final copy = Uint8List.fromList(bytes);
      resourceBytesByUuid[uuid] = copy;
      if (!isHtmlLesson) {
        pdfBytesByUuid[uuid] = copy;
      }
    }

    final preferenceObject = _jsonObject(
      payloads,
      'personal-data/preferences.json',
    );
    final rawPreferenceValues = preferenceObject['values'];
    if (rawPreferenceValues is! Map) {
      throw const FormatException(
        'The backup preferences payload has no valid values object.',
      );
    }

    final preferenceValues = <String, Object>{};
    for (final entry in rawPreferenceValues.entries) {
      if (entry.key is! String ||
          !(entry.value is String ||
              entry.value is bool ||
              entry.value is int ||
              entry.value is double)) {
        throw const FormatException(
          'The backup contains an unsupported preference value.',
        );
      }
      preferenceValues[entry.key as String] = entry.value as Object;
    }

    return PreparedFullLibraryBackup(
      formatVersion: backup.formatVersion,
      createdAt: backup.createdAt,
      taxonomy: taxonomyModels,
      notes: noteModels,
      citations: citationModels,
      bookmarks: bookmarkModels,
      history: historyModels,
      resources: resourceModels,
      pdfBytesByUuid: Map.unmodifiable(pdfBytesByUuid),
      resourceBytesByUuid: Map.unmodifiable(resourceBytesByUuid),
      preferenceValues: Map.unmodifiable(preferenceValues),
    );
  }

  static List<Map<String, dynamic>> _jsonList(
    Map<String, Uint8List> payloads,
    String path,
  ) {
    final bytes = payloads[path];
    if (bytes == null) {
      throw FormatException('Required backup payload "$path" is missing.');
    }

    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! List) {
      throw FormatException('Backup payload "$path" must contain a list.');
    }

    return decoded.map((value) {
      if (value is! Map) {
        throw FormatException(
          'Backup payload "$path" contains a non-object record.',
        );
      }
      return Map<String, dynamic>.from(value);
    }).toList(growable: false);
  }

  static Map<String, dynamic> _jsonObject(
    Map<String, Uint8List> payloads,
    String path,
  ) {
    final bytes = payloads[path];
    if (bytes == null) {
      throw FormatException('Required backup payload "$path" is missing.');
    }

    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw FormatException('Backup payload "$path" must contain an object.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static SyncMetadataModel _sync(Object? value) {
    if (value is! Map) {
      throw const FormatException('A record has invalid sync metadata.');
    }
    final row = Map<String, dynamic>.from(value);

    final remoteId = row['remoteId'];
    final lastSyncedAt = row['lastSyncedAt'];
    if (remoteId != null && remoteId is! String) {
      throw const FormatException('Sync remoteId must be a string or null.');
    }
    if (lastSyncedAt != null && lastSyncedAt is! String) {
      throw const FormatException(
        'Sync lastSyncedAt must be a timestamp string or null.',
      );
    }

    return SyncMetadataModel()
      ..remoteId = remoteId as String?
      ..lastModifiedLocal = _dateTime(row, 'lastModifiedLocal')
      ..lastSyncedAt =
          lastSyncedAt == null ? null : DateTime.parse(lastSyncedAt as String)
      ..isDirty = _bool(row, 'isDirty')
      ..isDeleted = _bool(row, 'isDeleted')
      ..deviceId = _string(row, 'deviceId')
      ..syncRevision = _int(row, 'syncRevision');
  }

  static String _string(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! String) {
      throw FormatException('Backup field "$key" must be a string.');
    }
    return value;
  }

  static String? _nullableString(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value != null && value is! String) {
      throw FormatException(
        'Backup field "$key" must be a string or null.',
      );
    }
    return value as String?;
  }

  static int _int(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! int) {
      throw FormatException('Backup field "$key" must be an integer.');
    }
    return value;
  }

  static int? _nullableInt(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value != null && value is! int) {
      throw FormatException(
        'Backup field "$key" must be an integer or null.',
      );
    }
    return value as int?;
  }

  static bool _bool(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! bool) {
      throw FormatException('Backup field "$key" must be a boolean.');
    }
    return value;
  }

  static DateTime _dateTime(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! String) {
      throw FormatException('Backup field "$key" must be a timestamp.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Backup field "$key" is not a valid timestamp.');
    }
    return parsed;
  }

  static List<String> _stringList(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('Backup field "$key" must be a list of strings.');
    }
    return value.cast<String>().toList(growable: true);
  }
}

/// Fully decoded snapshot data, ready for a later restore/commit phase.
///
/// This object contains no Isar-internal IDs and has not mutated live state.
class PreparedFullLibraryBackup {
  const PreparedFullLibraryBackup({
    required this.formatVersion,
    required this.createdAt,
    required this.taxonomy,
    required this.notes,
    required this.citations,
    required this.bookmarks,
    required this.history,
    required this.resources,
    required this.pdfBytesByUuid,
    Map<String, Uint8List>? resourceBytesByUuid,
    required this.preferenceValues,
  }) : resourceBytesByUuid = resourceBytesByUuid ?? pdfBytesByUuid;

  final int formatVersion;
  final DateTime createdAt;
  final List<TaxonomyNodeModel> taxonomy;
  final List<NoteModel> notes;
  final List<CitationModel> citations;
  final List<BookmarkModel> bookmarks;
  final List<HistoryModel> history;
  final List<LearningResourceModel> resources;

  /// PDF payloads retained for existing PDF-specific callers.
  final Map<String, Uint8List> pdfBytesByUuid;

  /// All resource payloads, keyed by resource UUID.
  final Map<String, Uint8List> resourceBytesByUuid;

  final Map<String, Object> preferenceValues;
}
