import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/core/database/sync_metadata_model.dart';
import 'package:medvault_app/core/storage/learning_resource_file_storage.dart';
import 'package:medvault_app/features/library/data/models/bookmark_model.dart';
import 'package:medvault_app/features/library/data/models/citation_model.dart';
import 'package:medvault_app/features/library/data/models/history_model.dart';
import 'package:medvault_app/features/library/data/models/learning_resource_model.dart';
import 'package:medvault_app/features/library/data/models/note_model.dart';
import 'package:medvault_app/features/library/data/models/taxonomy_node_model.dart';
import 'package:medvault_app/features/library/data/repositories/full_library_backup_exporter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    0x25,
    0x53,
    0x79,
    0x6E,
    0x74,
    0x68,
    0x65,
    0x74,
    0x69,
    0x63,
    0x20,
    0x50,
    0x44,
    0x46,
    0x0A,
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'appearance.themePreference': 'dark',
      'reading.textSize': 'large',
      'pdf_reader_continuous_mode': true,
      'pdf_reader_last_page_resource-backup-test': 7,
      'reader.scrollOffset.note-backup-test': 123.5,
      'unrelated.preference': 'must-not-be-exported',
    });

    tempDir = await Directory.systemTemp.createTemp(
      'medvault_full_backup_test_',
    );

    isar = await Isar.open(
      [
        TaxonomyNodeModelSchema,
        NoteModelSchema,
        CitationModelSchema,
        BookmarkModelSchema,
        HistoryModelSchema,
        LearningResourceModelSchema,
      ],
      directory: tempDir.path,
    );

    storage = LearningResourceFileStorage(
      documentsDirectoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('exports portable content, recovery data, PDFs and valid checksums',
      () async {
    final sourcePdf = File('${tempDir.path}/synthetic-source.pdf');
    await sourcePdf.writeAsBytes(pdfBytes);

    final relativePath = await storage.importPdf(sourcePdf.path);
    final importedAt = DateTime.utc(2026, 10, 19, 12);

    final resource = LearningResourceModel()
      ..uuid = 'resource-backup-test'
      ..topicUuid = 'topic-backup-test'
      ..title = 'Synthetic PDF'
      ..originalFileName = 'synthetic-source.pdf'
      ..relativeFilePath = relativePath
      ..fileSizeBytes = pdfBytes.length
      ..importedAt = importedAt;

    final sync = SyncMetadataModel()
      ..lastModifiedLocal = DateTime.utc(2026, 10, 19)
      ..isDirty = true
      ..isDeleted = false
      ..deviceId = 'test-device'
      ..syncRevision = 4;

    final bookmark = BookmarkModel()
      ..uuid = 'bookmark-backup-test'
      ..noteUuid = 'resource-backup-test'
      ..label = 'Continue here'
      ..createdAt = DateTime.utc(2026, 10, 19, 13)
      ..sync = sync;

    final history = HistoryModel()
      ..uuid = 'history-backup-test'
      ..noteUuid = 'resource-backup-test'
      ..viewedAt = DateTime.utc(2026, 10, 19, 14)
      ..sync = sync;

    await isar.writeTxn(() async {
      await isar.learningResourceModels.put(resource);
      await isar.bookmarkModels.put(bookmark);
      await isar.historyModels.put(history);
    });

    final originalResourceCount = await isar.learningResourceModels.count();

    final zipBytes = await FullLibraryBackupExporter(
      isar: isar,
      fileStorage: storage,
      generatePackUuid: () => 'synthetic-backup-pack',
      clock: () => DateTime.utc(2026, 10, 22),
    ).exportZip();

    final archive = ZipDecoder().decodeBytes(zipBytes);
    final files = <String, ArchiveFile>{
      for (final file in archive.files)
        if (file.isFile) file.name: file,
    };

    expect(
      files.keys,
      containsAll([
        'backup-manifest.json',
        'curriculum-pack.json',
        'database/taxonomy.json',
        'database/notes.json',
        'database/citations.json',
        'personal-data/bookmarks.json',
        'personal-data/history.json',
        'personal-data/preferences.json',
        'resources/metadata.json',
        'resources/pdfs/resource-backup-test.pdf',
      ]),
    );

    List<int> bytesFor(String path) => files[path]!.content as List<int>;

    Map<String, dynamic> jsonMap(String path) =>
        jsonDecode(utf8.decode(bytesFor(path))) as Map<String, dynamic>;

    final packJson = jsonMap('curriculum-pack.json');
    expect(packJson['manifest']['packUuid'], 'synthetic-backup-pack');

    final metadata = jsonDecode(
      utf8.decode(bytesFor('resources/metadata.json')),
    ) as List<dynamic>;
    expect(metadata, hasLength(1));

    final resourceMetadata = metadata.single as Map<String, dynamic>;
    expect(resourceMetadata['uuid'], 'resource-backup-test');
    expect(resourceMetadata['topicUuid'], 'topic-backup-test');
    expect(resourceMetadata['title'], 'Synthetic PDF');
    expect(resourceMetadata['originalFileName'], 'synthetic-source.pdf');
    expect(resourceMetadata['fileSizeBytes'], pdfBytes.length);
    expect(
      resourceMetadata['archivePath'],
      'resources/pdfs/resource-backup-test.pdf',
    );
    expect(resourceMetadata.containsKey('relativeFilePath'), isFalse);
    expect(resourceMetadata.containsKey('absoluteFilePath'), isFalse);

    expect(
      Uint8List.fromList(bytesFor('resources/pdfs/resource-backup-test.pdf')),
      orderedEquals(pdfBytes),
    );

    final bookmarks = jsonDecode(
      utf8.decode(bytesFor('personal-data/bookmarks.json')),
    ) as List<dynamic>;
    final bookmarkJson = bookmarks.single as Map<String, dynamic>;
    expect(bookmarkJson['uuid'], 'bookmark-backup-test');
    expect(bookmarkJson['label'], 'Continue here');
    expect(bookmarkJson['sync']['deviceId'], 'test-device');
    expect(bookmarkJson['sync']['syncRevision'], 4);

    final historyJson = jsonDecode(
      utf8.decode(bytesFor('personal-data/history.json')),
    ) as List<dynamic>;
    expect(
      (historyJson.single as Map<String, dynamic>)['uuid'],
      'history-backup-test',
    );

    final preferenceValues = jsonMap('personal-data/preferences.json')['values']
        as Map<String, dynamic>;
    expect(preferenceValues['appearance.themePreference'], 'dark');
    expect(preferenceValues['reading.textSize'], 'large');
    expect(preferenceValues['pdf_reader_continuous_mode'], true);
    expect(
      preferenceValues['pdf_reader_last_page_resource-backup-test'],
      7,
    );
    expect(preferenceValues['reader.scrollOffset.note-backup-test'], 123.5);
    expect(preferenceValues.containsKey('unrelated.preference'), isFalse);

    final manifest = jsonMap('backup-manifest.json');
    expect(manifest['formatVersion'], 1);
    expect(manifest['createdAt'], '2026-10-22T00:00:00.000Z');

    final checksums = manifest['payloads'] as Map<String, dynamic>;
    expect(checksums.containsKey('backup-manifest.json'), isFalse);
    expect(
        checksums.keys,
        containsAll(
          files.keys.where((path) => path != 'backup-manifest.json'),
        ));

    for (final entry in checksums.entries) {
      final metadata = entry.value as Map<String, dynamic>;
      final payloadBytes = bytesFor(entry.key);
      expect(metadata['sizeBytes'], payloadBytes.length, reason: entry.key);
      expect(
        metadata['sha256'],
        sha256.convert(payloadBytes).toString(),
        reason: entry.key,
      );
    }

    expect(
      await isar.learningResourceModels.count(),
      originalResourceCount,
    );
    expect(
      await isar.learningResourceModels
          .filter()
          .uuidEqualTo('resource-backup-test')
          .count(),
      1,
    );
    expect(await sourcePdf.exists(), isTrue);
  });
}
