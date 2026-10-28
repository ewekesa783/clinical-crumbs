import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:medvault_shared/medvault_shared.dart';

import '../topic_packages/prototype_html_lesson_archive_reader.dart';

/// Validates ZIP integrity, snapshot records, and cross-references.
///
/// This validator is deliberately read-only. It never changes Isar,
/// preferences, device identity, or managed PDF storage.
class FullLibraryBackupValidator {
  const FullLibraryBackupValidator();

  static const int supportedFormatVersion = 1;

  static const Set<String> _requiredPayloadPaths = {
    'curriculum-pack.json',
    'database/taxonomy.json',
    'database/notes.json',
    'database/citations.json',
    'personal-data/bookmarks.json',
    'personal-data/history.json',
    'personal-data/preferences.json',
    'resources/metadata.json',
  };

  static const Set<String> _nodeTypes = {
    'subject',
    'system',
    'topic',
    'custom',
  };
  static const Set<String> _noteModes = {
    'detailedNotes',
    'visualLearning',
    'quickReview',
  };
  static const Set<String> _sourceTypes = {
    'textbook',
    'journalArticle',
    'guideline',
    'lectureSlide',
    'other',
  };
  static const Set<String> _themeValues = {'system', 'light', 'dark'};
  static const Set<String> _textSizeValues = {
    'small',
    'normal',
    'large',
    'extraLarge',
  };

  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  ValidatedFullLibraryBackup validate(Uint8List zipBytes) {
    if (zipBytes.isEmpty) {
      throw const FormatException('The backup file is empty.');
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (_) {
      throw const FormatException(
        'The backup is not a valid or readable ZIP archive.',
      );
    }

    final files = <String, List<int>>{};
    for (final entry in archive.files) {
      final path = entry.name;
      if (!entry.isFile ||
          !_isSafeArchivePath(path) ||
          files.containsKey(path)) {
        throw const FormatException(
          'The backup contains an unsafe, duplicate, or unsupported ZIP entry.',
        );
      }
      files[path] = List<int>.from(entry.content as List<int>);
    }

    final manifestBytes = files['backup-manifest.json'];
    if (manifestBytes == null) {
      throw const FormatException('The backup manifest is missing.');
    }

    final manifest = _decodeJsonObject(
      manifestBytes,
      'backup-manifest.json',
    );
    if (manifest['formatVersion'] != supportedFormatVersion) {
      throw const FormatException(
        'This backup format version is not supported.',
      );
    }

    final createdAtValue = manifest['createdAt'];
    if (createdAtValue is! String ||
        DateTime.tryParse(createdAtValue) == null) {
      throw const FormatException(
        'The backup manifest has an invalid creation timestamp.',
      );
    }

    final declaredPayloads = manifest['payloads'];
    if (declaredPayloads is! Map) {
      throw const FormatException(
        'The backup manifest has an invalid payload list.',
      );
    }

    final checksums = <String, Map<String, dynamic>>{};
    for (final entry in declaredPayloads.entries) {
      if (entry.key is! String ||
          entry.value is! Map ||
          !_isSafeArchivePath(entry.key as String)) {
        throw const FormatException(
          'The backup manifest contains an invalid payload entry.',
        );
      }

      final path = entry.key as String;
      if (path == 'backup-manifest.json') {
        throw const FormatException(
          'The manifest must not include itself in its payload list.',
        );
      }

      final Map<String, dynamic> metadata;
      try {
        metadata = Map<String, dynamic>.from(entry.value as Map);
      } catch (_) {
        throw FormatException(
          'The backup manifest has invalid integrity metadata for "$path".',
        );
      }

      final checksum = metadata['sha256'];
      final sizeBytes = metadata['sizeBytes'];
      if (checksum is! String ||
          !_sha256Pattern.hasMatch(checksum) ||
          sizeBytes is! int ||
          sizeBytes < 0) {
        throw FormatException(
          'The backup manifest has invalid integrity metadata for "$path".',
        );
      }
      checksums[path] = metadata;
    }

    final actualPaths =
        files.keys.where((p) => p != 'backup-manifest.json').toSet();
    if (actualPaths.length != checksums.length ||
        !actualPaths.containsAll(checksums.keys) ||
        !checksums.keys.toSet().containsAll(actualPaths)) {
      throw const FormatException(
        'The archive contents do not match the manifest payload list.',
      );
    }

    if (!actualPaths.containsAll(_requiredPayloadPaths)) {
      throw const FormatException(
        'The backup is incomplete: one or more required payloads are missing.',
      );
    }

    for (final path in actualPaths) {
      if (!_isAllowedPayloadPath(path)) {
        throw FormatException(
          'The backup contains an unexpected payload: "$path".',
        );
      }

      final bytes = files[path]!;
      final metadata = checksums[path]!;
      if (bytes.length != metadata['sizeBytes']) {
        throw FormatException(
          'The backup payload size does not match its manifest: "$path".',
        );
      }
      if (sha256.convert(bytes).toString() != metadata['sha256']) {
        throw FormatException(
          'The backup payload checksum is invalid: "$path".',
        );
      }

      if (path.startsWith('resources/pdfs/')) {
        final name = path.substring('resources/pdfs/'.length);
        final uuid =
            name.endsWith('.pdf') ? name.substring(0, name.length - 4) : '';
        if (!_uuidPattern.hasMatch(uuid) ||
            bytes.length < 5 ||
            bytes[0] != 0x25 ||
            bytes[1] != 0x50 ||
            bytes[2] != 0x44 ||
            bytes[3] != 0x46 ||
            bytes[4] != 0x2D) {
          throw FormatException(
            'The backup contains an invalid PDF payload: "$path".',
          );
        }
      } else if (path.startsWith('resources/html_lessons/')) {
        try {
          const PrototypeHtmlLessonArchiveReader().read(
            Uint8List.fromList(bytes),
          );
        } catch (_) {
          throw FormatException(
            'The backup contains an invalid HTML lesson package: "$path".',
          );
        }
      }
    }

    final payloads = <String, Uint8List>{
      for (final path in actualPaths) path: Uint8List.fromList(files[path]!),
    };

    _validateSnapshot(payloads);

    return ValidatedFullLibraryBackup(
      formatVersion: supportedFormatVersion,
      createdAt: DateTime.parse(createdAtValue),
      payloads: payloads,
    );
  }

  void _validateSnapshot(Map<String, Uint8List> payloads) {
    final taxonomy = _decodeJsonList(
      payloads['database/taxonomy.json']!,
      'database/taxonomy.json',
    );
    final notes = _decodeJsonList(
      payloads['database/notes.json']!,
      'database/notes.json',
    );
    final citations = _decodeJsonList(
      payloads['database/citations.json']!,
      'database/citations.json',
    );
    final bookmarks = _decodeJsonList(
      payloads['personal-data/bookmarks.json']!,
      'personal-data/bookmarks.json',
    );
    final history = _decodeJsonList(
      payloads['personal-data/history.json']!,
      'personal-data/history.json',
    );
    final resources = _decodeJsonList(
      payloads['resources/metadata.json']!,
      'resources/metadata.json',
    );

    final taxonomyById = <String, Map<String, dynamic>>{};
    for (var i = 0; i < taxonomy.length; i++) {
      final row = taxonomy[i];
      final at = 'database/taxonomy.json[$i]';
      final id = _uuid(row['uuid'], '$at.uuid');
      if (taxonomyById.containsKey(id)) {
        _fail('$at.uuid is duplicated.');
      }
      taxonomyById[id] = row;

      final parent = _nullableString(row['parentUuid'], '$at.parentUuid');
      if (parent != null) _uuid(parent, '$at.parentUuid');
      _string(row['path'], '$at.path');
      _nonNegativeInt(row['depth'], '$at.depth');
      _enumValue(row['nodeType'], _nodeTypes, '$at.nodeType');
      _nonEmptyString(row['title'], '$at.title');
      _nonEmptyString(row['slug'], '$at.slug');
      _nullableString(row['shortDescription'], '$at.shortDescription');
      _nullableString(row['iconKey'], '$at.iconKey');
      _nonNegativeInt(row['sortOrder'], '$at.sortOrder');
      _nonNegativeInt(row['noteCount'], '$at.noteCount');
      _nullableString(row['curriculumPackUuid'], '$at.curriculumPackUuid');
      final packVersion = row['curriculumPackVersion'];
      if (packVersion != null) {
        _nonNegativeInt(packVersion, '$at.curriculumPackVersion');
      }
      _bool(row['isUserCreated'], '$at.isUserCreated');
      _timestamp(row['createdAt'], '$at.createdAt');
      _timestamp(row['updatedAt'], '$at.updatedAt');
      _validateSync(row['sync'], '$at.sync');
    }

    for (final entry in taxonomyById.entries) {
      final parent = entry.value['parentUuid'] as String?;
      if (parent != null && !taxonomyById.containsKey(parent)) {
        _fail('Taxonomy "${entry.key}" references missing parent "$parent".');
      }
    }
    _validateTaxonomyCycles(taxonomyById);

    final citationIds = <String>{};
    for (var i = 0; i < citations.length; i++) {
      final row = citations[i];
      final at = 'database/citations.json[$i]';
      final id = _uuid(row['uuid'], '$at.uuid');
      if (!citationIds.add(id)) _fail('$at.uuid is duplicated.');
      _enumValue(row['sourceType'], _sourceTypes, '$at.sourceType');
      _nonEmptyString(row['title'], '$at.title');
      _nullableString(row['authors'], '$at.authors');
      final year = row['publicationYear'];
      if (year != null && (year is! int || year < 1000 || year > 9999)) {
        _fail(
            '$at.publicationYear must be null or an integer from 1000 to 9999.');
      }
      _nullableString(row['pageReference'], '$at.pageReference');
      final url = _nullableString(row['url'], '$at.url');
      if (url != null) {
        final uri = Uri.tryParse(url);
        if (uri == null ||
            (uri.scheme != 'http' && uri.scheme != 'https') ||
            uri.host.isEmpty) {
          _fail('$at.url must be a valid HTTP or HTTPS URL.');
        }
      }
      _timestamp(row['createdAt'], '$at.createdAt');
      _timestamp(row['updatedAt'], '$at.updatedAt');
      _validateSync(row['sync'], '$at.sync');
    }

    final noteIds = <String>{};
    final noteModes = <String>{};
    for (var i = 0; i < notes.length; i++) {
      final row = notes[i];
      final at = 'database/notes.json[$i]';
      final id = _uuid(row['uuid'], '$at.uuid');
      if (!noteIds.add(id)) _fail('$at.uuid is duplicated.');
      final topicId = _uuid(row['topicUuid'], '$at.topicUuid');
      if (!taxonomyById.containsKey(topicId)) {
        _fail('$at.topicUuid references missing taxonomy node "$topicId".');
      }
      final mode = _enumValue(row['mode'], _noteModes, '$at.mode');
      final composite = '$topicId\u0000$mode';
      if (!noteModes.add(composite)) {
        _fail('A note duplicates the topic and mode pair "$topicId / $mode".');
      }
      _nonEmptyString(row['title'], '$at.title');
      _nonEmptyString(row['bodyMarkdown'], '$at.bodyMarkdown');
      _nullableString(row['plainTextExtract'], '$at.plainTextExtract');
      _stringList(row['tags'], '$at.tags', requireNonEmptyItems: true);
      final citationOrder = _stringList(
        row['citationOrder'],
        '$at.citationOrder',
      );
      final seenCitations = <String>{};
      for (final citationId in citationOrder) {
        _uuid(citationId, '$at.citationOrder');
        if (!seenCitations.add(citationId)) {
          _fail('$at.citationOrder contains duplicate citation "$citationId".');
        }
        if (!citationIds.contains(citationId)) {
          _fail('$at.citationOrder references missing citation "$citationId".');
        }
      }
      _bool(row['isPinned'], '$at.isPinned');
      _timestamp(row['createdAt'], '$at.createdAt');
      _timestamp(row['updatedAt'], '$at.updatedAt');
      _validateSync(row['sync'], '$at.sync');
    }

    final bookmarkIds = <String>{};
    for (var i = 0; i < bookmarks.length; i++) {
      final row = bookmarks[i];
      final at = 'personal-data/bookmarks.json[$i]';
      final id = _uuid(row['uuid'], '$at.uuid');
      if (!bookmarkIds.add(id)) _fail('$at.uuid is duplicated.');
      final noteId = _uuid(row['noteUuid'], '$at.noteUuid');
      if (!noteIds.contains(noteId)) {
        _fail('$at.noteUuid references missing note "$noteId".');
      }
      _nullableString(row['label'], '$at.label');
      _timestamp(row['createdAt'], '$at.createdAt');
      _validateSync(row['sync'], '$at.sync');
    }

    final historyIds = <String>{};
    final historyNoteIds = <String>{};
    for (var i = 0; i < history.length; i++) {
      final row = history[i];
      final at = 'personal-data/history.json[$i]';
      final id = _uuid(row['uuid'], '$at.uuid');
      if (!historyIds.add(id)) _fail('$at.uuid is duplicated.');
      final noteId = _uuid(row['noteUuid'], '$at.noteUuid');
      if (!noteIds.contains(noteId)) {
        _fail('$at.noteUuid references missing note "$noteId".');
      }
      if (!historyNoteIds.add(noteId)) {
        _fail('History contains more than one entry for note "$noteId".');
      }
      _timestamp(row['viewedAt'], '$at.viewedAt');
      _validateSync(row['sync'], '$at.sync');
    }

    final resourceIds = <String>{};
    final referencedPdfPaths = <String>{};
    final referencedHtmlPaths = <String>{};
    for (var i = 0; i < resources.length; i++) {
      final row = resources[i];
      final at = 'resources/metadata.json[$i]';
      final id = _uuid(row['uuid'], '$at.uuid');
      if (!resourceIds.add(id)) _fail('$at.uuid is duplicated.');
      final topicId = _uuid(row['topicUuid'], '$at.topicUuid');
      if (!taxonomyById.containsKey(topicId)) {
        _fail('$at.topicUuid references missing taxonomy node "$topicId".');
      }
      _nonEmptyString(row['title'], '$at.title');
      _nonEmptyString(row['originalFileName'], '$at.originalFileName');

      // Version-1 backups created before HTML lessons have no format field.
      final formatValue = row['format'] ?? 'pdf';
      if (formatValue is! String ||
          (formatValue != 'pdf' && formatValue != 'htmlLesson')) {
        _fail('$at.format must be "pdf" or "htmlLesson".');
      }

      final isHtmlLesson = formatValue == 'htmlLesson';
      final size = _nonNegativeInt(row['fileSizeBytes'], '$at.fileSizeBytes');
      if (size < 5) {
        _fail('$at.fileSizeBytes is too small for a resource payload.');
      }
      _timestamp(row['importedAt'], '$at.importedAt');

      final archivePath =
          _nonEmptyString(row['archivePath'], '$at.archivePath');
      final expectedPath = isHtmlLesson
          ? 'resources/html_lessons/$id.zip'
          : 'resources/pdfs/$id.pdf';
      if (archivePath != expectedPath) {
        _fail('$at.archivePath must be "$expectedPath".');
      }

      final bytes = payloads[archivePath];
      if (bytes == null) {
        _fail(
          'Resource "$id" has no matching '
          '${isHtmlLesson ? "HTML lesson package" : "PDF"} payload.',
        );
      }
      if (bytes.length != size) {
        _fail('Resource "$id" fileSizeBytes does not match its payload.');
      }

      if (isHtmlLesson) {
        referencedHtmlPaths.add(archivePath);
      } else {
        referencedPdfPaths.add(archivePath);
      }
    }

    final actualPdfPaths = payloads.keys
        .where((path) => path.startsWith('resources/pdfs/'))
        .toSet();
    if (actualPdfPaths.length != referencedPdfPaths.length ||
        !actualPdfPaths.containsAll(referencedPdfPaths)) {
      _fail('The backup contains missing or unreferenced PDF payloads.');
    }

    final actualHtmlPaths = payloads.keys
        .where((path) => path.startsWith('resources/html_lessons/'))
        .toSet();
    if (actualHtmlPaths.length != referencedHtmlPaths.length ||
        !actualHtmlPaths.containsAll(referencedHtmlPaths)) {
      _fail(
        'The backup contains missing or unreferenced HTML lesson packages.',
      );
    }

    _validatePreferences(payloads['personal-data/preferences.json']!);
    _validateCurriculumPack(
      payloads['curriculum-pack.json']!,
      taxonomyById.keys.toSet(),
      noteIds,
      citationIds,
    );
  }

  void _validateCurriculumPack(
    Uint8List bytes,
    Set<String> taxonomyIds,
    Set<String> noteIds,
    Set<String> citationIds,
  ) {
    final json = _decodeJsonObject(bytes, 'curriculum-pack.json');
    try {
      final pack = CurriculumPack.fromJson(json);
      final result = const CurriculumPackValidator().validate(pack);
      if (!result.isValid) {
        _fail(
            'The portable curriculum pack is invalid: ${result.issues.first}');
      }
      final packTaxonomyIds = pack.taxonomyNodes.map((e) => e.uuid).toSet();
      final packNoteIds = pack.notes.map((e) => e.uuid).toSet();
      final packCitationIds = pack.citations.map((e) => e.uuid).toSet();
      if (!_sameSet(packTaxonomyIds, taxonomyIds) ||
          !_sameSet(packNoteIds, noteIds) ||
          !_sameSet(packCitationIds, citationIds)) {
        _fail(
            'The portable curriculum pack does not match the full snapshot IDs.');
      }
    } on FormatException {
      rethrow;
    } catch (error) {
      _fail('The portable curriculum pack has an invalid structure: $error');
    }
  }

  void _validatePreferences(Uint8List bytes) {
    final root = _decodeJsonObject(bytes, 'personal-data/preferences.json');
    final values = root['values'];
    if (values is! Map) {
      _fail('personal-data/preferences.json must contain a values object.');
    }

    for (final entry in values.entries) {
      if (entry.key is! String) {
        _fail('A preference key is not a string.');
      }
      final key = entry.key as String;
      final value = entry.value;

      if (key == 'appearance.themePreference') {
        _enumValue(value, _themeValues, 'preference "$key"');
      } else if (key == 'reading.textSize') {
        _enumValue(value, _textSizeValues, 'preference "$key"');
      } else if (key == 'pdf_reader_continuous_mode') {
        _bool(value, 'preference "$key"');
      } else if (key == 'clinical_crumbs_starter_content_ledger_v1') {
        _validateStarterContentLedger(value);
      } else if (key.startsWith('pdf_reader_last_page_')) {
        final id = key.substring('pdf_reader_last_page_'.length);
        _uuid(id, 'preference key "$key"');
        if (value is! int || value < 1) {
          _fail(
              'Preference "$key" must be an integer page number of at least 1.');
        }
      } else if (key.startsWith('reader.scrollOffset.')) {
        final id = key.substring('reader.scrollOffset.'.length);
        _uuid(id, 'preference key "$key"');
        if (value is! num || !value.isFinite || value < 0) {
          _fail('Preference "$key" must be a finite non-negative number.');
        }
      } else {
        _fail('The backup contains an unsupported preference key "$key".');
      }
    }
  }

  void _validateStarterContentLedger(Object? value) {
    if (value is! String) {
      _fail('The starter-content ledger preference must be a JSON string.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      _fail('The starter-content ledger contains invalid JSON.');
    }

    if (decoded is! Map) {
      _fail('The starter-content ledger must contain a JSON object.');
    }

    for (final key in ['knownResourceUuids', 'deletedResourceUuids']) {
      final entries = decoded[key];
      if (entries is! List ||
          entries.any((entry) => entry is! String) ||
          entries.toSet().length != entries.length) {
        _fail(
            'The starter-content ledger field "$key" must be a list of unique UUID strings.');
      }

      for (final entry in entries) {
        _uuid(entry, 'starter-content ledger "$key"');
      }
    }
  }

  void _validateTaxonomyCycles(Map<String, Map<String, dynamic>> nodes) {
    for (final start in nodes.keys) {
      final visited = <String>{};
      String? current = start;
      while (current != null) {
        if (!visited.add(current)) {
          _fail(
              'The taxonomy hierarchy contains a cycle involving "$current".');
        }
        current = nodes[current]?['parentUuid'] as String?;
      }
    }
  }

  void _validateSync(Object? value, String at) {
    if (value is! Map) _fail('$at must be an object.');
    final map = Map<String, dynamic>.from(value);
    _nullableString(map['remoteId'], '$at.remoteId');
    _timestamp(map['lastModifiedLocal'], '$at.lastModifiedLocal');
    final lastSynced = map['lastSyncedAt'];
    if (lastSynced != null) _timestamp(lastSynced, '$at.lastSyncedAt');
    _bool(map['isDirty'], '$at.isDirty');
    _bool(map['isDeleted'], '$at.isDeleted');
    _string(map['deviceId'], '$at.deviceId');
    _nonNegativeInt(map['syncRevision'], '$at.syncRevision');
  }

  List<Map<String, dynamic>> _decodeJsonList(
    Uint8List bytes,
    String path,
  ) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw FormatException('The backup file "$path" is not valid JSON.');
    }
    if (decoded is! List) {
      throw FormatException(
          'The backup file "$path" must contain a JSON array.');
    }
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < decoded.length; i++) {
      if (decoded[i] is! Map) {
        throw FormatException('$path[$i] must be a JSON object.');
      }
      try {
        result.add(Map<String, dynamic>.from(decoded[i] as Map));
      } catch (_) {
        throw FormatException('$path[$i] is not a valid JSON object.');
      }
    }
    return result;
  }

  Map<String, dynamic> _decodeJsonObject(List<int> bytes, String path) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Use one consistent error below.
    }
    throw FormatException(
      'The backup file "$path" does not contain a valid JSON object.',
    );
  }

  String _uuid(Object? value, String at) {
    if (value is! String || !_uuidPattern.hasMatch(value)) {
      _fail('$at must be a valid UUID.');
    }
    return value;
  }

  String _string(Object? value, String at) {
    if (value is! String) _fail('$at must be a string.');
    return value;
  }

  String _nonEmptyString(Object? value, String at) {
    final result = _string(value, at);
    if (result.trim().isEmpty) _fail('$at must not be empty.');
    return result;
  }

  String? _nullableString(Object? value, String at) {
    if (value == null) return null;
    return _string(value, at);
  }

  int _nonNegativeInt(Object? value, String at) {
    if (value is! int || value < 0) {
      _fail('$at must be a non-negative integer.');
    }
    return value;
  }

  bool _bool(Object? value, String at) {
    if (value is! bool) _fail('$at must be a Boolean.');
    return value;
  }

  DateTime _timestamp(Object? value, String at) {
    if (value is! String) _fail('$at must be an ISO-8601 timestamp.');
    final parsed = DateTime.tryParse(value);
    if (parsed == null) _fail('$at must be a valid ISO-8601 timestamp.');
    return parsed;
  }

  String _enumValue(Object? value, Set<String> allowed, String at) {
    if (value is! String || !allowed.contains(value)) {
      _fail('$at has an unsupported value.');
    }
    return value;
  }

  List<String> _stringList(
    Object? value,
    String at, {
    bool requireNonEmptyItems = false,
  }) {
    if (value is! List || value.any((item) => item is! String)) {
      _fail('$at must be an array of strings.');
    }
    final result = List<String>.from(value);
    if (requireNonEmptyItems && result.any((item) => item.trim().isEmpty)) {
      _fail('$at must not contain empty strings.');
    }
    return result;
  }

  bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  Never _fail(String message) => throw FormatException(message);

  bool _isSafeArchivePath(String path) {
    if (path.isEmpty ||
        path.startsWith('/') ||
        path.contains(r'\') ||
        path.endsWith('/')) {
      return false;
    }
    return path.split('/').every(
          (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
        );
  }

  bool _isAllowedPayloadPath(String path) {
    if (_requiredPayloadPaths.contains(path)) return true;

    if (path.startsWith('resources/pdfs/')) {
      final name = path.substring('resources/pdfs/'.length);
      return name.endsWith('.pdf') &&
          _uuidPattern.hasMatch(name.substring(0, name.length - 4));
    }

    if (path.startsWith('resources/html_lessons/')) {
      final name = path.substring('resources/html_lessons/'.length);
      return name.endsWith('.zip') &&
          _uuidPattern.hasMatch(name.substring(0, name.length - 4));
    }

    return false;
  }
}

/// A checksum-verified, semantically validated backup snapshot.
class ValidatedFullLibraryBackup {
  const ValidatedFullLibraryBackup({
    required this.formatVersion,
    required this.createdAt,
    required this.payloads,
  });

  final int formatVersion;
  final DateTime createdAt;
  final Map<String, Uint8List> payloads;
}
