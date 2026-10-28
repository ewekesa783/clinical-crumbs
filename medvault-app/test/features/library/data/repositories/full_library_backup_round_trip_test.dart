import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/core/database/sync_metadata_model.dart';
import 'package:medvault_app/core/storage/learning_resource_file_storage.dart';
import 'package:medvault_app/core/storage/device_identity_model.dart';
import 'package:medvault_app/features/library/data/models/bookmark_model.dart';
import 'package:medvault_app/features/library/data/models/citation_model.dart';
import 'package:medvault_app/features/library/data/models/history_model.dart';
import 'package:medvault_app/features/library/data/models/learning_resource_model.dart';
import 'package:medvault_app/features/library/data/models/note_model.dart';
import 'package:medvault_app/features/library/data/models/taxonomy_node_model.dart';
import 'package:medvault_app/features/library/data/repositories/full_library_backup_exporter.dart';
import 'package:medvault_app/features/library/data/repositories/full_library_backup_preparer.dart';
import 'package:medvault_app/features/library/data/repositories/full_library_backup_restorer.dart';
import 'package:medvault_app/features/library/data/repositories/full_library_backup_validator.dart';
import 'package:medvault_app/features/library/domain/entities/citation.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';
import 'package:shared_preferences/shared_preferences.dart';

const topicId = '11111111-1111-4111-8111-111111111111';
const noteId = '22222222-2222-4222-8222-222222222222';
const citationId = '33333333-3333-4333-8333-333333333333';
const bookmarkId = '44444444-4444-4444-8444-444444444444';
const historyId = '55555555-5555-4555-8555-555555555555';
const resourceId = '66666666-6666-4666-8666-666666666666';

void main() {
  late Isar isar;
  late Directory tempDir;
  late LearningResourceFileStorage storage;

  const pdfBytes = <int>[
    0x25,
    0x50,
    0x44,
    0x46,
    0x2D,
    0x31,
    0x2E,
    0x37,
    0x0A,
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'appearance.themePreference': 'system',
      'reading.textSize': 'normal',
      'pdf_reader_continuous_mode': true,
      'pdf_reader_last_page_$resourceId': 1,
      'reader.scrollOffset.$noteId': 0.0,
      'clinical_crumbs_starter_content_ledger_v1': jsonEncode({
        'knownResourceUuids': [
          resourceId,
          '77777777-7777-4777-8777-777777777777',
        ],
        'deletedResourceUuids': ['77777777-7777-4777-8777-777777777777'],
      }),
    });

    tempDir = await Directory.systemTemp.createTemp(
      'clinical_crumbs_backup_round_trip_',
    );

    isar = await Isar.open(
      [
        TaxonomyNodeModelSchema,
        NoteModelSchema,
        CitationModelSchema,
        BookmarkModelSchema,
        HistoryModelSchema,
        LearningResourceModelSchema,
        DeviceIdentityModelSchema,
      ],
      directory: tempDir.path,
    );

    storage = LearningResourceFileStorage(
      documentsDirectoryProvider: () async => tempDir,
    );

    await isar.writeTxn(() async {
      await isar.deviceIdentityModels.put(
        DeviceIdentityModel()..deviceId = 'preserve-this-installation',
      );
    });
  });

  tearDown(() async {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('exported full backup passes the strict backup validator', () async {
    final now = DateTime.utc(2026, 10, 22);
    SyncMetadataModel newSync() => SyncMetadataModel()
      ..lastModifiedLocal = now
      ..isDirty = true
      ..isDeleted = false
      ..deviceId = 'round-trip-test-device'
      ..syncRevision = 0;

    final topic = TaxonomyNodeModel()
      ..uuid = topicId
      ..parentUuid = null
      ..path = topicId
      ..depth = 0
      ..nodeType = NodeType.topic
      ..title = 'Round-trip topic'
      ..slug = 'round-trip-topic'
      ..shortDescription = null
      ..iconKey = null
      ..sortOrder = 0
      ..noteCount = 1
      ..curriculumPackUuid = null
      ..curriculumPackVersion = null
      ..isUserCreated = false
      ..createdAt = now
      ..updatedAt = now
      ..sync = newSync();

    final citation = CitationModel()
      ..uuid = citationId
      ..sourceType = SourceType.textbook
      ..title = 'Round-trip reference'
      ..authors = null
      ..publicationYear = 2024
      ..pageReference = null
      ..url = null
      ..createdAt = now
      ..updatedAt = now
      ..sync = newSync();

    final note = NoteModel()
      ..uuid = noteId
      ..topicUuid = topicId
      ..mode = Mode.detailedNotes
      ..title = 'Round-trip note'
      ..bodyMarkdown = 'Test body'
      ..plainTextExtract = null
      ..tags = ['test']
      ..citationOrder = [citationId]
      ..isPinned = false
      ..createdAt = now
      ..updatedAt = now
      ..sync = newSync();

    final bookmark = BookmarkModel()
      ..uuid = bookmarkId
      ..noteUuid = noteId
      ..label = null
      ..createdAt = now
      ..sync = newSync();

    final history = HistoryModel()
      ..uuid = historyId
      ..noteUuid = noteId
      ..viewedAt = now
      ..sync = newSync();

    final sourcePdf = File('${tempDir.path}/round-trip.pdf');
    await sourcePdf.writeAsBytes(pdfBytes);
    final relativePath = await storage.importPdf(sourcePdf.path);

    final resource = LearningResourceModel()
      ..uuid = resourceId
      ..topicUuid = topicId
      ..title = 'Round-trip PDF'
      ..originalFileName = 'round-trip.pdf'
      ..relativeFilePath = relativePath
      ..fileSizeBytes = pdfBytes.length
      ..importedAt = now;

    await isar.writeTxn(() async {
      await isar.taxonomyNodeModels.put(topic);
      await isar.citationModels.put(citation);
      await isar.noteModels.put(note);
      await isar.bookmarkModels.put(bookmark);
      await isar.historyModels.put(history);
      await isar.learningResourceModels.put(resource);
    });

    final zipBytes = await FullLibraryBackupExporter(
      isar: isar,
      fileStorage: storage,
      generatePackUuid: () => '88888888-8888-4888-8888-888888888888',
      preferences: await SharedPreferences.getInstance(),
      clock: () => now,
    ).exportZip();

    final result = const FullLibraryBackupValidator().validate(zipBytes);

    expect(result.formatVersion, FullLibraryBackupExporter.formatVersion);
    expect(result.createdAt, now);
    expect(
      jsonDecode(utf8.decode(result.payloads['database/taxonomy.json']!)),
      hasLength(1),
    );
    expect(
      jsonDecode(utf8.decode(result.payloads['database/notes.json']!)),
      hasLength(1),
    );
    expect(
      jsonDecode(utf8.decode(result.payloads['database/citations.json']!)),
      hasLength(1),
    );
    expect(
      jsonDecode(utf8.decode(result.payloads['personal-data/bookmarks.json']!)),
      hasLength(1),
    );
    expect(
      jsonDecode(utf8.decode(result.payloads['personal-data/history.json']!)),
      hasLength(1),
    );
    expect(
      result.payloads['resources/pdfs/$resourceId.pdf'],
      orderedEquals(pdfBytes),
    );

    // Preparation must decode the full snapshot without changing live state.
    final countsBefore = (
      taxonomy: await isar.taxonomyNodeModels.count(),
      notes: await isar.noteModels.count(),
      citations: await isar.citationModels.count(),
      bookmarks: await isar.bookmarkModels.count(),
      history: await isar.historyModels.count(),
      resources: await isar.learningResourceModels.count(),
    );
    final originalPdf = await storage.resolvePdf(relativePath);

    final prepared = const FullLibraryBackupPreparer().prepare(zipBytes);

    expect(prepared.formatVersion, FullLibraryBackupExporter.formatVersion);
    expect(prepared.createdAt, now);

    expect(prepared.taxonomy, hasLength(1));
    expect(prepared.taxonomy.single.uuid, topicId);
    expect(prepared.taxonomy.single.title, 'Round-trip topic');

    expect(prepared.notes, hasLength(1));
    expect(prepared.notes.single.uuid, noteId);
    expect(prepared.notes.single.topicUuid, topicId);
    expect(prepared.notes.single.citationOrder, [citationId]);
    expect(prepared.notes.single.isPinned, isFalse);

    expect(prepared.citations, hasLength(1));
    expect(prepared.citations.single.uuid, citationId);
    expect(prepared.citations.single.title, 'Round-trip reference');

    expect(prepared.bookmarks, hasLength(1));
    expect(prepared.bookmarks.single.uuid, bookmarkId);
    expect(prepared.bookmarks.single.noteUuid, noteId);

    expect(prepared.history, hasLength(1));
    expect(prepared.history.single.uuid, historyId);
    expect(prepared.history.single.noteUuid, noteId);

    expect(prepared.resources, hasLength(1));
    expect(prepared.resources.single.uuid, resourceId);
    expect(
      prepared.resources.single.relativeFilePath,
      'learning_resources/pdfs/$resourceId.pdf',
    );
    expect(
      prepared.pdfBytesByUuid[resourceId],
      orderedEquals(pdfBytes),
    );

    expect(
      prepared.preferenceValues,
      containsPair('appearance.themePreference', 'system'),
    );
    expect(
      prepared.preferenceValues,
      containsPair('reading.textSize', 'normal'),
    );
    expect(
      prepared.preferenceValues,
      containsPair('pdf_reader_continuous_mode', true),
    );
    expect(
      prepared.preferenceValues,
      containsPair('pdf_reader_last_page_$resourceId', 1),
    );
    expect(
      prepared.preferenceValues,
      containsPair('reader.scrollOffset.$noteId', 0.0),
    );
    expect(
      jsonDecode(
        prepared.preferenceValues['clinical_crumbs_starter_content_ledger_v1']
            as String,
      ),
      {
        'knownResourceUuids': [
          resourceId,
          '77777777-7777-4777-8777-777777777777',
        ],
        'deletedResourceUuids': ['77777777-7777-4777-8777-777777777777'],
      },
    );

    expect(
      (
        taxonomy: await isar.taxonomyNodeModels.count(),
        notes: await isar.noteModels.count(),
        citations: await isar.citationModels.count(),
        bookmarks: await isar.bookmarkModels.count(),
        history: await isar.historyModels.count(),
        resources: await isar.learningResourceModels.count(),
      ),
      countsBefore,
    );
    expect(await originalPdf.exists(), isTrue);
    expect(await originalPdf.readAsBytes(), orderedEquals(pdfBytes));

    // Seed unrelated live data after the snapshot: restore must replace,
    // not merge, and must preserve this installation's identity.
    final extraTopic = TaxonomyNodeModel()
      ..uuid = '77777777-7777-4777-8777-777777777777'
      ..parentUuid = null
      ..path = '77777777-7777-4777-8777-777777777777'
      ..depth = 0
      ..nodeType = NodeType.topic
      ..title = 'Extra live topic'
      ..slug = 'extra-live-topic'
      ..shortDescription = null
      ..iconKey = null
      ..sortOrder = 1
      ..noteCount = 0
      ..curriculumPackUuid = null
      ..curriculumPackVersion = null
      ..isUserCreated = true
      ..createdAt = now
      ..updatedAt = now
      ..sync = newSync();

    await isar.writeTxn(() async {
      await isar.taxonomyNodeModels.put(extraTopic);
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('appearance.themePreference', 'dark');

    await FullLibraryBackupRestorer(
      isar: isar,
      preferences: preferences,
      documentsDirectoryProvider: () async => tempDir,
    ).restore(zipBytes);

    expect(await isar.taxonomyNodeModels.count(), 1);
    expect(
      (await isar.taxonomyNodeModels.where().findAll())
          .any((node) => node.uuid == '77777777-7777-4777-8777-777777777777'),
      isFalse,
    );
    expect(
      (await isar.deviceIdentityModels.where().findAll()).single.deviceId,
      'preserve-this-installation',
    );
    expect(
      preferences.getString('appearance.themePreference'),
      'system',
    );
    expect(
      jsonDecode(
        preferences.getString('clinical_crumbs_starter_content_ledger_v1')!,
      ),
      {
        'knownResourceUuids': [
          resourceId,
          '77777777-7777-4777-8777-777777777777',
        ],
        'deletedResourceUuids': ['77777777-7777-4777-8777-777777777777'],
      },
    );
    final restoredPdf = await storage.resolvePdf(
      'learning_resources/pdfs/$resourceId.pdf',
    );
    expect(await restoredPdf.readAsBytes(), orderedEquals(pdfBytes));
  });


  test('HTML lesson package survives backup export, preparation and restore',
      () async {
    const htmlResourceId = '99999999-9999-4999-8999-999999999999';
    final now = DateTime.utc(2026, 10, 22);
    final html = utf8.encode(
      '<!doctype html><html><head><meta charset="utf-8">'
      '<title>Offline lesson</title></head>'
      '<body><main>Original lesson content</main></body></html>',
    );
    final archive = Archive()
      ..addFile(ArchiveFile('index.html', html.length, html));
    final packageBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    final sourcePackage = File('${tempDir.path}/offline-lesson.zip');
    await sourcePackage.writeAsBytes(packageBytes);
    final relativePath =
        await storage.importHtmlLessonPackage(sourcePackage.path);

    SyncMetadataModel newSync() => SyncMetadataModel()
      ..lastModifiedLocal = now
      ..isDirty = true
      ..isDeleted = false
      ..deviceId = 'html-round-trip-test-device'
      ..syncRevision = 0;

    final topic = TaxonomyNodeModel()
      ..uuid = topicId
      ..parentUuid = null
      ..path = topicId
      ..depth = 0
      ..nodeType = NodeType.topic
      ..title = 'HTML round-trip topic'
      ..slug = 'html-round-trip-topic'
      ..shortDescription = null
      ..iconKey = null
      ..sortOrder = 0
      ..noteCount = 0
      ..curriculumPackUuid = null
      ..curriculumPackVersion = null
      ..isUserCreated = false
      ..createdAt = now
      ..updatedAt = now
      ..sync = newSync();

    final resource = LearningResourceModel()
      ..uuid = htmlResourceId
      ..topicUuid = topicId
      ..title = 'Offline lesson'
      ..originalFileName = 'offline-lesson.zip'
      ..relativeFilePath = relativePath
      ..fileSizeBytes = packageBytes.length
      ..importedAt = now;

    await isar.writeTxn(() async {
      await isar.taxonomyNodeModels.put(topic);
      await isar.learningResourceModels.put(resource);
    });

    final preferences = await SharedPreferences.getInstance();
    final backup = await FullLibraryBackupExporter(
      isar: isar,
      fileStorage: storage,
      generatePackUuid: () => '88888888-8888-4888-8888-888888888888',
      preferences: preferences,
      clock: () => now,
    ).exportZip();

    final validated = const FullLibraryBackupValidator().validate(backup);
    const archivePath = 'resources/html_lessons/$htmlResourceId.zip';
    expect(validated.payloads[archivePath], orderedEquals(packageBytes));

    final prepared = const FullLibraryBackupPreparer().prepare(backup);
    expect(prepared.resources, hasLength(1));
    expect(
      prepared.resources.single.relativeFilePath,
      'learning_resources/html_lessons/$htmlResourceId.zip',
    );
    expect(
      prepared.resourceBytesByUuid[htmlResourceId],
      orderedEquals(packageBytes),
    );

    await FullLibraryBackupRestorer(
      isar: isar,
      preferences: preferences,
      documentsDirectoryProvider: () async => tempDir,
    ).restore(backup);

    final restoredFile = await storage.resolveHtmlLessonPackage(
      'learning_resources/html_lessons/$htmlResourceId.zip',
    );
    expect(await restoredFile.readAsBytes(), orderedEquals(packageBytes));
    expect(await sourcePackage.readAsBytes(), orderedEquals(packageBytes));
    expect(await isar.learningResourceModels.count(), 1);
  });

  test('rejects an invalid backup without changing live state', () async {
    final preferences = await SharedPreferences.getInstance();
    final originalTheme = preferences.getString('appearance.themePreference');

    final restorer = FullLibraryBackupRestorer(
      isar: isar,
      preferences: preferences,
      documentsDirectoryProvider: () async => tempDir,
    );

    await expectLater(
      restorer.restore(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(anything),
    );

    expect(await isar.taxonomyNodeModels.count(), 0);
    expect(await isar.noteModels.count(), 0);
    expect(await isar.citationModels.count(), 0);
    expect(await isar.bookmarkModels.count(), 0);
    expect(await isar.historyModels.count(), 0);
    expect(await isar.learningResourceModels.count(), 0);

    final identities = await isar.deviceIdentityModels.where().findAll();
    expect(identities, hasLength(1));
    expect(identities.single.deviceId, 'preserve-this-installation');

    expect(
      preferences.getString('appearance.themePreference'),
      originalTheme,
    );

    final activePdfDirectory = Directory(
      '${tempDir.path}/learning_resources/pdfs',
    );
    expect(await activePdfDirectory.exists(), isFalse);
  });
}
