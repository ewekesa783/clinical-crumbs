import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/library/data/updates/remote_content_release_downloader.dart';
import 'package:medvault_app/features/library/data/updates/remote_content_update_service.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:medvault_app/core/storage/learning_resource_file_storage.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/bootstrap/starter_library_initializer.dart';
import 'package:medvault_app/features/library/data/bootstrap/starter_content_ledger.dart';
import 'package:medvault_app/features/library/data/models/bookmark_model.dart';
import 'package:medvault_app/features/library/data/models/citation_model.dart';
import 'package:medvault_app/features/library/data/models/history_model.dart';
import 'package:medvault_app/features/library/data/models/learning_resource_model.dart';
import 'package:medvault_app/features/library/data/models/note_model.dart';
import 'package:medvault_app/features/library/data/models/taxonomy_node_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Isar isar;
  late Directory tempDir;
  late LearningResourceFileStorage storage;
  late SharedPreferences preferences;
  late StarterLibraryInitializer initializer;
  late Uint8List bundledArchiveBytes;

  Future<Uint8List> loadBundledArchive() async {
    return Uint8List.fromList(
      await File('assets/bootstrap/medvault-starter-library.zip').readAsBytes(),
    );
  }

  Uint8List buildUnversionedArchive(Uint8List sourceBytes) {
    final decoded = ZipDecoder().decodeBytes(sourceBytes);
    final archive = Archive();

    for (final file in decoded.files) {
      if (!file.isFile || file.name == 'content-manifest.json') continue;
      final bytes = file.content as List<int>;
      archive.addFile(ArchiveFile(file.name, bytes.length, bytes));
    }

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Uint8List buildArchiveWithResources(Set<String> resourceUuids) {
    final decoded = ZipDecoder().decodeBytes(bundledArchiveBytes);
    final sourceFiles = {
      for (final file in decoded.files)
        if (file.isFile) file.name: file,
    };

    final metadata = jsonDecode(
      utf8.decode(
        sourceFiles['resources/metadata.json']!.content as List<int>,
      ),
    ) as List<dynamic>;

    final selectedMetadata = metadata.where((entry) {
      final item = entry as Map<String, dynamic>;
      return resourceUuids.contains(item['uuid']);
    }).toList();

    final archive = Archive();

    void addBytes(String name, List<int> bytes) {
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    addBytes(
      'curriculum-pack.json',
      sourceFiles['curriculum-pack.json']!.content as List<int>,
    );

    addBytes(
      'resources/metadata.json',
      utf8.encode(jsonEncode(selectedMetadata)),
    );

    for (final entry in selectedMetadata) {
      final item = entry as Map<String, dynamic>;
      final archivePath = item['archivePath'] as String;
      addBytes(
        archivePath,
        sourceFiles[archivePath]!.content as List<int>,
      );
    }

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  dynamic canonicalizeJson(dynamic value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return <String, dynamic>{
        for (final key in keys) key: canonicalizeJson(value[key]),
      };
    }
    if (value is List) {
      return value.map(canonicalizeJson).toList();
    }
    return value;
  }

  String jsonChecksum(dynamic value) {
    return sha256
        .convert(utf8.encode(jsonEncode(canonicalizeJson(value))))
        .toString();
  }

  Uint8List buildVersionedArchive({
    int contentVersion = 1,
    bool corruptPdfChecksum = false,
    bool corruptTaxonomyChecksum = false,
    String? changedResourceUuid,
    List<int>? changedResourceBytes,
    String? changedResourceTitle,
  }) {
    final decoded = ZipDecoder().decodeBytes(bundledArchiveBytes);
    final sourceFiles = {
      for (final file in decoded.files)
        if (file.isFile) file.name: file,
    };

    final pack = jsonDecode(
      utf8.decode(sourceFiles['curriculum-pack.json']!.content as List<int>),
    ) as Map<String, dynamic>;
    final metadata = jsonDecode(
      utf8.decode(sourceFiles['resources/metadata.json']!.content as List<int>),
    ) as List<dynamic>;

    if ((changedResourceUuid == null) != (changedResourceBytes == null)) {
      throw ArgumentError(
        'A changed resource UUID and its bytes must be supplied together.',
      );
    }
    if (changedResourceUuid != null) {
      final resource =
          metadata.map((value) => value as Map<String, dynamic>).firstWhere(
                (value) => value['uuid'] == changedResourceUuid,
                orElse: () => throw ArgumentError(
                  'The requested resource UUID is not in the starter archive.',
                ),
              );
      final archivePath = resource['archivePath'] as String;
      if (!archivePath.startsWith('resources/pdfs/')) {
        throw ArgumentError('This fixture only changes PDF resources.');
      }
      final bytes = Uint8List.fromList(changedResourceBytes!);
      sourceFiles[archivePath] = ArchiveFile(archivePath, bytes.length, bytes);
      resource['fileSizeBytes'] = bytes.length;
      if (changedResourceTitle != null) {
        resource['title'] = changedResourceTitle;
      }
      final updatedMetadataBytes = utf8.encode(jsonEncode(metadata));
      sourceFiles['resources/metadata.json'] = ArchiveFile(
        'resources/metadata.json',
        updatedMetadataBytes.length,
        updatedMetadataBytes,
      );
    }

    final taxonomyEntries = (pack['taxonomyNodes'] as List<dynamic>)
        .map((value) {
      final node = value as Map<String, dynamic>;
      return {
        'uuid': node['uuid'],
        'sha256': jsonChecksum(node),
      };
    }).toList()
      ..sort((a, b) => (a['uuid'] as String).compareTo(b['uuid'] as String));

    if (corruptTaxonomyChecksum) {
      taxonomyEntries.first['sha256'] = '0' * 64;
    }

    final resourceEntries = metadata.map((value) {
      final resource = value as Map<String, dynamic>;
      final archivePath = resource['archivePath'] as String;
      final pdfBytes = sourceFiles[archivePath]!.content as List<int>;
      return <String, dynamic>{
        'uuid': resource['uuid'],
        'topicUuid': resource['topicUuid'],
        'title': resource['title'],
        'archivePath': archivePath,
        'fileSizeBytes': pdfBytes.length,
        'sha256': sha256.convert(pdfBytes).toString(),
      };
    }).toList()
      ..sort((a, b) => (a['uuid'] as String).compareTo(b['uuid'] as String));

    if (changedResourceUuid != null && changedResourceTitle != null) {
      final changedEntry = resourceEntries.firstWhere(
        (entry) => entry['uuid'] == changedResourceUuid,
      );
      changedEntry['title'] = changedResourceTitle;
    }

    if (corruptPdfChecksum) {
      resourceEntries.first['sha256'] = '0' * 64;
    }

    final packManifest = pack['manifest'] as Map<String, dynamic>;
    final contentManifest = <String, dynamic>{
      'schemaVersion': 1,
      'contentVersion': contentVersion,
      'sourcePackUuid': packManifest['packUuid'],
      'sourcePackVersion': packManifest['version'],
      'taxonomy': taxonomyEntries,
      'resources': resourceEntries,
    };

    final archive = Archive();
    for (final file in sourceFiles.values) {
      final bytes = file.content as List<int>;
      archive.addFile(ArchiveFile(file.name, bytes.length, bytes));
    }
    final manifestBytes = utf8.encode(jsonEncode(contentManifest));
    archive.addFile(
      ArchiveFile('content-manifest.json', manifestBytes.length, manifestBytes),
    );
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Uint8List buildVersionedArchiveWithHtmlLesson({
    int contentVersion = 2,
    String lessonHeading = 'HTML lesson test',
    List<int>? lessonPackageBytes,
  }) {
    final decoded = ZipDecoder().decodeBytes(
      buildVersionedArchive(contentVersion: contentVersion),
    );
    final files = <String, ArchiveFile>{
      for (final file in decoded.files)
        if (file.isFile) file.name: file,
    };

    final metadata = jsonDecode(
      utf8.decode(files['resources/metadata.json']!.content as List<int>),
    ) as List<dynamic>;
    final resource = metadata.first as Map<String, dynamic>;
    final uuid = resource['uuid'] as String;
    final oldPath = resource['archivePath'] as String;
    final htmlPath = 'resources/html_lessons/$uuid.zip';

    late final Uint8List htmlBytes;
    if (lessonPackageBytes != null) {
      htmlBytes = Uint8List.fromList(lessonPackageBytes);
    } else {
      final lessonArchive = Archive();
      final html = utf8.encode(
        '<!doctype html><html><head><title>Test lesson</title></head>'
        '<body><h1>$lessonHeading</h1></body></html>',
      );
      lessonArchive.addFile(ArchiveFile('index.html', html.length, html));
      htmlBytes = Uint8List.fromList(ZipEncoder().encode(lessonArchive));
    }

    resource['archivePath'] = htmlPath;
    resource['originalFileName'] = 'test-lesson.zip';
    resource['fileSizeBytes'] = htmlBytes.length;

    final manifest = jsonDecode(
      utf8.decode(files['content-manifest.json']!.content as List<int>),
    ) as Map<String, dynamic>;
    final manifestResources = manifest['resources'] as List<dynamic>;
    final manifestEntry = manifestResources.firstWhere(
      (entry) => (entry as Map<String, dynamic>)['uuid'] == uuid,
    ) as Map<String, dynamic>;
    manifestEntry['archivePath'] = htmlPath;
    manifestEntry['fileSizeBytes'] = htmlBytes.length;
    manifestEntry['sha256'] = sha256.convert(htmlBytes).toString();

    final output = Archive();
    for (final entry in files.entries) {
      if (entry.key == oldPath ||
          entry.key == 'resources/metadata.json' ||
          entry.key == 'content-manifest.json') {
        continue;
      }
      final bytes = entry.value.content as List<int>;
      output.addFile(ArchiveFile(entry.key, bytes.length, bytes));
    }

    void addJson(String path, Object value) {
      final bytes = utf8.encode(jsonEncode(value));
      output.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    addJson('resources/metadata.json', metadata);
    addJson('content-manifest.json', manifest);
    output.addFile(ArchiveFile(htmlPath, htmlBytes.length, htmlBytes));

    return Uint8List.fromList(ZipEncoder().encode(output));
  }

  Future<Set<String>> loadPackagedPdfUuids() async {
    final archive = ZipDecoder().decodeBytes(await loadBundledArchive());
    final files = {
      for (final file in archive.files)
        if (file.isFile) file.name: file,
    };
    final metadata = jsonDecode(
      utf8.decode(files['resources/metadata.json']!.content as List<int>),
    ) as List<dynamic>;

    return metadata
        .map((value) => value as Map<String, dynamic>)
        .where((item) =>
            (item['archivePath'] as String).startsWith('resources/pdfs/'))
        .map((item) => item['uuid'] as String)
        .toSet();
  }

  Future<Map<String, Set<String>>> loadExpectedPackageUuids() async {
    final archive = ZipDecoder().decodeBytes(await loadBundledArchive());
    final files = {
      for (final file in archive.files)
        if (file.isFile) file.name: file,
    };

    final packJson = jsonDecode(
      utf8.decode(files['curriculum-pack.json']!.content as List<int>),
    ) as Map<String, dynamic>;

    final metadata = jsonDecode(
      utf8.decode(files['resources/metadata.json']!.content as List<int>),
    ) as List<dynamic>;

    return {
      'taxonomy': (packJson['taxonomyNodes'] as List<dynamic>)
          .map((node) => (node as Map<String, dynamic>)['uuid'] as String)
          .toSet(),
      'resources': metadata
          .map((item) => (item as Map<String, dynamic>)['uuid'] as String)
          .toSet(),
    };
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'medvault_starter_initializer_test_',
    );

    final isarDir = Directory('${tempDir.path}/isar');
    await isarDir.create(recursive: true);

    isar = await Isar.open(
      [
        TaxonomyNodeModelSchema,
        NoteModelSchema,
        CitationModelSchema,
        BookmarkModelSchema,
        HistoryModelSchema,
        LearningResourceModelSchema,
      ],
      directory: isarDir.path,
    );

    storage = LearningResourceFileStorage(
      documentsDirectoryProvider: () async => tempDir,
    );

    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    bundledArchiveBytes = buildUnversionedArchive(await loadBundledArchive());

    initializer = StarterLibraryInitializer(
      isar: isar,
      fileStorage: storage,
      preferences: preferences,
      createSyncMetadata: () => SyncMetadata(
        remoteId: null,
        lastModifiedLocal: DateTime.utc(2026, 1, 1),
        lastSyncedAt: null,
        isDirty: true,
        isDeleted: false,
        deviceId: 'starter-initializer-test',
        syncRevision: 1,
      ),
      now: () => DateTime.utc(2026, 1, 1),
      assetLoader: () async => bundledArchiveBytes,
    );
  });

  tearDown(() async {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'downloads and applies a release from the laptop server through the update service',
    () async {
      final releaseUrl = Platform.environment['CLINICAL_CRUMBS_RELEASE_URL'];
      if (releaseUrl == null || releaseUrl.isEmpty) {
        markTestSkipped(
          'Set CLINICAL_CRUMBS_RELEASE_URL to run the laptop-server integration test.',
        );
        return;
      }

      final service = RemoteContentUpdateService(
        preferences: preferences,
        initializer: initializer,
      );

      try {
        expect(
          await service.downloadAndApply(
            releaseUri: Uri.parse(releaseUrl),
          ),
          isTrue,
        );
        expect(await isar.learningResourceModels.count(), greaterThan(0));
        expect(
          StarterContentLedger(preferences).installedContentVersion,
          1,
        );
      } finally {
        service.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('downloads and applies an archive with a valid release checksum',
      () async {
    final archiveBytes = buildVersionedArchive(contentVersion: 2);
    final decodedArchive = ZipDecoder().decodeBytes(archiveBytes);
    final files = {
      for (final file in decodedArchive.files)
        if (file.isFile) file.name: file,
    };
    final manifest = jsonDecode(
      utf8.decode(files['content-manifest.json']!.content as List<int>),
    ) as Map<String, dynamic>;
    final release = {
      'schemaVersion': 1,
      'contentVersion': 2,
      'archiveUrl': 'http://127.0.0.1:8765/archive.zip',
      'archiveSha256': sha256.convert(archiveBytes).toString(),
      'manifest': manifest,
    };

    final client = MockClient((request) async {
      if (request.url.path == '/release.json') {
        return http.Response(jsonEncode(release), 200);
      }
      if (request.url.path == '/archive.zip') {
        return http.Response.bytes(archiveBytes, 200);
      }
      return http.Response('Not found', 404);
    });

    final downloader = RemoteContentReleaseDownloader(
      preferences: preferences,
      initializer: initializer,
      client: client,
    );

    try {
      expect(
        await downloader.downloadAndApply(
          releaseUri: Uri.parse('http://127.0.0.1:8765/release.json'),
        ),
        isTrue,
      );
      expect(await isar.learningResourceModels.count(), greaterThan(0));
      expect(
        StarterContentLedger(preferences).installedContentVersion,
        2,
      );
    } finally {
      downloader.close();
      client.close();
    }
  });

  test('rejects an archive with a mismatched release checksum', () async {
    final archiveBytes = buildVersionedArchive(contentVersion: 2);
    final decodedArchive = ZipDecoder().decodeBytes(archiveBytes);
    final files = {
      for (final file in decodedArchive.files)
        if (file.isFile) file.name: file,
    };
    final manifest = jsonDecode(
      utf8.decode(files['content-manifest.json']!.content as List<int>),
    ) as Map<String, dynamic>;
    final release = {
      'schemaVersion': 1,
      'contentVersion': 2,
      'archiveUrl': 'http://127.0.0.1:8765/archive.zip',
      'archiveSha256': '0' * 64,
      'manifest': manifest,
    };

    var archiveRequested = false;
    final client = MockClient((request) async {
      if (request.url.path == '/release.json') {
        return http.Response(jsonEncode(release), 200);
      }
      if (request.url.path == '/archive.zip') {
        archiveRequested = true;
        return http.Response.bytes(archiveBytes, 200);
      }
      return http.Response('Not found', 404);
    });

    final downloader = RemoteContentReleaseDownloader(
      preferences: preferences,
      initializer: initializer,
      client: client,
    );

    try {
      expect(
        await downloader.downloadAndApply(
          releaseUri: Uri.parse('http://127.0.0.1:8765/release.json'),
        ),
        isFalse,
      );
      expect(archiveRequested, isTrue);
      expect(await isar.learningResourceModels.count(), 0);
      expect(await isar.taxonomyNodeModels.count(), 0);
      expect(
        StarterContentLedger(preferences).installedContentVersion,
        isNull,
      );
    } finally {
      downloader.close();
      client.close();
    }
  });

  test(
    'accepts the Python-generated versioned candidate archive',
    () async {
      final candidatePath =
          Platform.environment['CLINICAL_CRUMBS_VERSIONED_ARCHIVE'];
      if (candidatePath == null || candidatePath.isEmpty) {
        return;
      }

      final candidateBytes = await File(candidatePath).readAsBytes();

      expect(
          await initializer.updateContentFromArchive(candidateBytes), isTrue);
      expect(await isar.learningResourceModels.count(), 29);
      expect(await isar.taxonomyNodeModels.count(), 394);
      expect(
        StarterContentLedger(preferences).installedContentVersion,
        2,
      );
    },
    skip: Platform.environment['CLINICAL_CRUMBS_VERSIONED_ARCHIVE'] == null
        ? 'Set CLINICAL_CRUMBS_VERSIONED_ARCHIVE to test the release candidate.'
        : false,
  );

  test('does not reapply an already-installed content version', () async {
    bundledArchiveBytes = buildVersionedArchive();

    expect(await initializer.updateBundledContent(), isTrue);

    final ledger = StarterContentLedger(
      await SharedPreferences.getInstance(),
    );
    expect(ledger.installedContentVersion, 1);

    final resourceCountBefore = await isar.learningResourceModels.count();
    final taxonomyCountBefore = await isar.taxonomyNodeModels.count();

    expect(await initializer.updateBundledContent(), isFalse);
    expect(await isar.learningResourceModels.count(), resourceCountBefore);
    expect(await isar.taxonomyNodeModels.count(), taxonomyCountBefore);
    expect(ledger.installedContentVersion, 1);
  });

  test('advances to a newer content release without duplicating content',
      () async {
    bundledArchiveBytes = buildVersionedArchive();
    expect(await initializer.updateBundledContent(), isTrue);

    final ledger = StarterContentLedger(
      await SharedPreferences.getInstance(),
    );
    final resourceCountBefore = await isar.learningResourceModels.count();
    final taxonomyCountBefore = await isar.taxonomyNodeModels.count();

    bundledArchiveBytes = buildVersionedArchive(contentVersion: 2);

    expect(await initializer.updateBundledContent(), isTrue);
    expect(ledger.installedContentVersion, 2);
    expect(await isar.learningResourceModels.count(), resourceCountBefore);
    expect(await isar.taxonomyNodeModels.count(), taxonomyCountBefore);
  });

  test('preserves an unchanged managed PDF on a newer release', () async {
    expect(
      await initializer.updateContentFromArchive(
        buildVersionedArchive(contentVersion: 1),
      ),
      isTrue,
    );

    final original =
        (await isar.learningResourceModels.where().findAll()).firstWhere(
      (resource) => resource.relativeFilePath.startsWith(
        'learning_resources/pdfs/',
      ),
    );
    final originalId = original.id;
    final originalUuid = original.uuid;
    final originalPath = original.relativeFilePath;
    final originalFile = await storage.resolvePdf(originalPath);
    final originalBytes = await originalFile.readAsBytes();

    expect(
      await initializer.updateContentFromArchive(
        buildVersionedArchive(contentVersion: 2),
      ),
      isTrue,
    );

    final updated = await isar.learningResourceModels
        .filter()
        .uuidEqualTo(originalUuid)
        .findFirst();

    expect(updated, isNotNull);
    expect(updated!.id, originalId);
    expect(updated.relativeFilePath, originalPath);
    expect(await originalFile.exists(), isTrue);
    expect(await originalFile.readAsBytes(), originalBytes);
    expect(StarterContentLedger(preferences).installedContentVersion, 2);
  });

  test('replaces a changed managed PDF in place on a newer release', () async {
    expect(
      await initializer.updateContentFromArchive(
        buildVersionedArchive(contentVersion: 1),
      ),
      isTrue,
    );

    final resourcesBefore = await isar.learningResourceModels.where().findAll();
    final original = resourcesBefore.firstWhere(
      (resource) => resource.relativeFilePath.startsWith(
        'learning_resources/pdfs/',
      ),
    );
    final originalId = original.id;
    final originalUuid = original.uuid;
    final originalPath = original.relativeFilePath;
    final originalFile = await storage.resolvePdf(originalPath);
    final originalBytes = await originalFile.readAsBytes();
    final updatedBytes = Uint8List.fromList(
      <int>[37, 80, 68, 70, 45, 50, 10, 37, 67, 67],
    );
    final updatedTitle = '${original.title} — revised';

    expect(
      await initializer.updateContentFromArchive(
        buildVersionedArchive(
          contentVersion: 2,
          changedResourceUuid: originalUuid,
          changedResourceBytes: updatedBytes,
          changedResourceTitle: updatedTitle,
        ),
      ),
      isTrue,
    );

    final updated = await isar.learningResourceModels
        .filter()
        .uuidEqualTo(originalUuid)
        .findFirst();

    expect(updated, isNotNull);
    expect(updated!.id, originalId);
    expect(updated.uuid, originalUuid);
    expect(updated.relativeFilePath, originalPath);
    expect(updated.title, updatedTitle);
    expect(updated.fileSizeBytes, updatedBytes.length);
    expect(await originalFile.readAsBytes(), updatedBytes);
    expect(await originalFile.readAsBytes(), isNot(equals(originalBytes)));
    expect(StarterContentLedger(preferences).installedContentVersion, 2);
  });

  test('installs HTML lesson ZIPs through the content update pipeline',
      () async {
    final archive = buildVersionedArchiveWithHtmlLesson();

    expect(
      await initializer.updateContentFromArchive(archive),
      isTrue,
    );

    final htmlResource = (await isar.learningResourceModels.where().findAll())
        .firstWhere(
            (resource) => resource.originalFileName == 'test-lesson.zip');

    expect(
      htmlResource.relativeFilePath,
      startsWith('learning_resources/html_lessons/'),
    );
    final file = await storage.resolveHtmlLessonPackage(
      htmlResource.relativeFilePath,
    );
    expect(await file.exists(), isTrue);
    expect(await file.length(), htmlResource.fileSizeBytes);
  });

  test('preserves an unchanged managed HTML lesson on a newer release',
      () async {
    expect(
      await initializer.updateContentFromArchive(
        buildVersionedArchiveWithHtmlLesson(
          contentVersion: 2,
          lessonHeading: 'Unchanged lesson',
        ),
      ),
      isTrue,
    );

    final original =
        (await isar.learningResourceModels.where().findAll()).firstWhere(
      (resource) => resource.originalFileName == 'test-lesson.zip',
    );
    final originalId = original.id;
    final originalUuid = original.uuid;
    final originalPath = original.relativeFilePath;
    final originalPackage =
        await storage.resolveHtmlLessonPackage(originalPath);
    final originalBytes = await originalPackage.readAsBytes();

    expect(
      await initializer.updateContentFromArchive(
        buildVersionedArchiveWithHtmlLesson(
          contentVersion: 3,
          lessonPackageBytes: originalBytes,
        ),
      ),
      isTrue,
    );

    final updated = await isar.learningResourceModels
        .filter()
        .uuidEqualTo(originalUuid)
        .findFirst();

    expect(updated, isNotNull);
    expect(updated!.id, originalId);
    expect(updated.relativeFilePath, originalPath);
    expect(await originalPackage.exists(), isTrue);
    expect(await originalPackage.readAsBytes(), originalBytes);
    expect(StarterContentLedger(preferences).installedContentVersion, 3);
  });

  test('replaces a changed managed HTML lesson after the database commit',
      () async {
    expect(
      await initializer.updateContentFromArchive(
        buildVersionedArchiveWithHtmlLesson(
          contentVersion: 2,
          lessonHeading: 'Original lesson',
        ),
      ),
      isTrue,
    );

    final original =
        (await isar.learningResourceModels.where().findAll()).firstWhere(
      (resource) => resource.originalFileName == 'test-lesson.zip',
    );
    final originalId = original.id;
    final originalUuid = original.uuid;
    final originalPath = original.relativeFilePath;
    final oldPackage = await storage.resolveHtmlLessonPackage(originalPath);
    expect(await oldPackage.exists(), isTrue);

    expect(
      await initializer.updateContentFromArchive(
        buildVersionedArchiveWithHtmlLesson(
          contentVersion: 3,
          lessonHeading: 'Revised lesson',
        ),
      ),
      isTrue,
    );

    final updated = await isar.learningResourceModels
        .filter()
        .uuidEqualTo(originalUuid)
        .findFirst();

    expect(updated, isNotNull);
    expect(updated!.id, originalId);
    expect(updated.uuid, originalUuid);
    expect(updated.relativeFilePath, isNot(originalPath));
    expect(updated.title, original.title);

    final newPackage =
        await storage.resolveHtmlLessonPackage(updated.relativeFilePath);
    expect(await newPackage.exists(), isTrue);
    expect(await newPackage.length(), updated.fileSizeBytes);
    expect(await oldPackage.exists(), isFalse);

    final newLessonArchive =
        ZipDecoder().decodeBytes(await newPackage.readAsBytes());
    final index = newLessonArchive.files.firstWhere(
      (file) => file.isFile && file.name == 'index.html',
    );
    expect(
      utf8.decode(index.content as List<int>),
      contains('Revised lesson'),
    );
    expect(StarterContentLedger(preferences).installedContentVersion, 3);
  });

  test('installs a versioned archive through the archive-based entry point',
      () async {
    final archive = buildVersionedArchive();

    expect(await initializer.updateContentFromArchive(archive), isTrue);
    expect(await isar.learningResourceModels.count(), 43);
    expect(await isar.taxonomyNodeModels.count(), 399);

    final ledger = StarterContentLedger(preferences);
    expect(ledger.installedContentVersion, 1);
  });

  test('rejects invalid archive bytes without changing the library', () async {
    final invalidArchive = Uint8List.fromList(
      <int>[0x6e, 0x6f, 0x74, 0x20, 0x61, 0x20, 0x7a, 0x69, 0x70],
    );

    expect(await initializer.updateContentFromArchive(invalidArchive), isFalse);
    expect(await isar.learningResourceModels.count(), 0);
    expect(await isar.taxonomyNodeModels.count(), 0);
  });

  test('rejects an archive whose manifest differs from the expected manifest',
      () async {
    final archive = buildVersionedArchive();

    expect(
      await initializer.updateContentFromArchive(
        archive,
        expectedManifest: {
          'schemaVersion': 1,
          'contentVersion': 99,
        },
      ),
      isFalse,
    );
    expect(await isar.learningResourceModels.count(), 0);
    expect(await isar.taxonomyNodeModels.count(), 0);
  });

  test('accepts a valid versioned starter archive', () async {
    final archive = buildVersionedArchive();

    expect(await initializer.updateContentFromArchive(archive), isTrue);
    expect(await isar.learningResourceModels.count(), 43);
    expect(await isar.taxonomyNodeModels.count(), 399);
  });

  test('rejects a versioned archive with an incorrect PDF checksum', () async {
    final archive = buildVersionedArchive(corruptPdfChecksum: true);

    expect(await initializer.updateContentFromArchive(archive), isFalse);
    expect(await isar.learningResourceModels.count(), 0);
    expect(await isar.taxonomyNodeModels.count(), 0);
  });

  test('rejects a versioned archive with an incorrect taxonomy checksum',
      () async {
    final archive = buildVersionedArchive(
      corruptTaxonomyChecksum: true,
    );

    expect(await initializer.updateContentFromArchive(archive), isFalse);
    expect(await isar.learningResourceModels.count(), 0);
    expect(await isar.taxonomyNodeModels.count(), 0);
  });

  test('restores all packaged taxonomy nodes and PDFs on a clean installation',
      () async {
    final expected = await loadExpectedPackageUuids();
    final restored = await initializer.updateBundledContent();

    expect(restored, isTrue);
    expect(
      (await isar.taxonomyNodeModels.where().findAll())
          .map((node) => node.uuid)
          .toSet(),
      expected['taxonomy'],
    );
    expect(
      (await isar.learningResourceModels.where().findAll())
          .map((resource) => resource.uuid)
          .toSet(),
      expected['resources'],
    );
    expect(
      await isar.learningResourceModels.count(),
      expected['resources']!.length,
    );
    expect(
      StarterContentLedger(preferences).knownResourceUuids,
      containsAll(expected['resources']!),
    );
    final resources = await isar.learningResourceModels.where().findAll();
    for (final resource in resources) {
      if (resource.relativeFilePath.startsWith('learning_resources/pdfs/')) {
        final file = await storage.resolvePdf(resource.relativeFilePath);
        expect(await file.exists(), isTrue);
        expect(await file.length(), resource.fileSizeBytes);
      } else {
        final file =
            await storage.resolveHtmlLessonPackage(resource.relativeFilePath);
        expect(await file.exists(), isTrue);
        expect(await file.length(), resource.fileSizeBytes);
      }
    }
  });

  test('skips restoration when a resource already exists', () async {
    final existing = LearningResourceModel()
      ..uuid = 'existing-resource'
      ..topicUuid = 'existing-topic'
      ..title = 'My existing PDF'
      ..originalFileName = 'my-existing.pdf'
      ..relativeFilePath = 'learning_resources/pdfs/existing-resource.pdf'
      ..fileSizeBytes = 123
      ..importedAt = DateTime.utc(2026, 1, 1);

    await isar.writeTxn(() async {
      await isar.learningResourceModels.put(existing);
    });

    final restored = await initializer.initializeIfEligible();

    expect(restored, isFalse);
    expect(await isar.learningResourceModels.count(), 1);
    expect(
      (await isar.learningResourceModels.get(existing.id))?.title,
      'My existing PDF',
    );
    expect(
      preferences.getBool(StarterLibraryInitializer.completionKey),
      isNot(true),
    );
  });

  test('upgrade from an older package adds only newly bundled resources',
      () async {
    final expected = await loadExpectedPackageUuids();
    final allResourceUuids = expected['resources']!;
    bundledArchiveBytes = buildUnversionedArchive(await loadBundledArchive());
    final pdfUuids = await loadPackagedPdfUuids();
    final olderResourceUuids = pdfUuids.take(2).toSet();

    bundledArchiveBytes = buildArchiveWithResources(olderResourceUuids);
    expect(await initializer.initializeIfEligible(), isTrue);
    expect(await isar.learningResourceModels.count(), 2);

    final originalResources =
        await isar.learningResourceModels.where().findAll();
    final originalUuids =
        originalResources.map((resource) => resource.uuid).toSet();
    expect(originalUuids, olderResourceUuids);

    final deletedResource = originalResources.first;
    await storage.deletePdf(deletedResource.relativeFilePath);
    await isar.writeTxn(() async {
      await isar.learningResourceModels.delete(deletedResource.id);
    });
    expect(
      await StarterContentLedger(preferences)
          .recordDeletionIfStarter(deletedResource.uuid),
      isTrue,
    );

    bundledArchiveBytes = await loadBundledArchive();
    expect(await initializer.updateBundledContent(), isTrue);

    final upgradedResources =
        await isar.learningResourceModels.where().findAll();
    final upgradedUuids =
        upgradedResources.map((resource) => resource.uuid).toSet();
    final expectedAfterUpgrade =
        allResourceUuids.difference({deletedResource.uuid});

    expect(upgradedUuids, expectedAfterUpgrade);
    expect(upgradedResources, hasLength(expectedAfterUpgrade.length));
    expect(upgradedUuids.intersection(originalUuids),
        originalUuids.difference({deletedResource.uuid}));
    expect(
      StarterContentLedger(preferences).deletedResourceUuids,
      contains(deletedResource.uuid),
    );

    for (final resource in upgradedResources) {
      expect(
        await File('${tempDir.path}/${resource.relativeFilePath}').exists(),
        isTrue,
      );
    }
  });

  test('incremental update adds starter content without duplicating it',
      () async {
    final expected = await loadExpectedPackageUuids();

    final existing = LearningResourceModel()
      ..uuid = 'user-imported-resource'
      ..topicUuid = 'user-created-topic'
      ..title = 'My existing PDF'
      ..originalFileName = 'my-existing.pdf'
      ..relativeFilePath = 'learning_resources/pdfs/user-imported-resource.pdf'
      ..fileSizeBytes = 123
      ..importedAt = DateTime.utc(2026, 1, 1);

    await isar.writeTxn(() async {
      await isar.learningResourceModels.put(existing);
    });

    expect(await initializer.updateBundledContent(), isTrue);
    expect(
      await isar.learningResourceModels.count(),
      expected['resources']!.length + 1,
    );
    expect(
      (await isar.learningResourceModels.where().findAll())
          .any((resource) => resource.uuid == existing.uuid),
      isTrue,
    );

    expect(await initializer.updateBundledContent(), isTrue);
    expect(
      await isar.learningResourceModels.count(),
      expected['resources']!.length + 1,
    );
  });

  test('preserves an unverified local resource sharing a release UUID',
      () async {
    final initialArchive = buildVersionedArchive(contentVersion: 1);
    final decoded = ZipDecoder().decodeBytes(initialArchive);
    final files = {
      for (final file in decoded.files)
        if (file.isFile) file.name: file,
    };
    final metadata = jsonDecode(
      utf8.decode(files['resources/metadata.json']!.content as List<int>),
    ) as List<dynamic>;
    final published = metadata
        .map((value) => value as Map<String, dynamic>)
        .firstWhere(
          (value) =>
              (value['archivePath'] as String).startsWith('resources/pdfs/'),
        );
    final uuid = published['uuid'] as String;
    final relativePath = 'learning_resources/pdfs/$uuid.pdf';
    final localBytes = Uint8List.fromList(
      <int>[37, 80, 68, 70, 45, 76, 79, 67, 65, 76],
    );
    final incomingBytes = Uint8List.fromList(
      <int>[37, 80, 68, 70, 45, 82, 69, 76, 69, 65, 83, 69],
    );

    final localFile = File('${tempDir.path}/$relativePath');
    await localFile.parent.create(recursive: true);
    await localFile.writeAsBytes(localBytes);

    final local = LearningResourceModel()
      ..uuid = uuid
      ..topicUuid = published['topicUuid'] as String
      ..title = 'My private local title'
      ..originalFileName = 'private-local.pdf'
      ..relativeFilePath = relativePath
      ..fileSizeBytes = localBytes.length
      ..importedAt = DateTime.utc(2026, 1, 1);

    await isar.writeTxn(() async {
      await isar.learningResourceModels.put(local);
    });

    final release = buildVersionedArchive(
      contentVersion: 1,
      changedResourceUuid: uuid,
      changedResourceBytes: incomingBytes,
      changedResourceTitle: 'Publisher revision',
    );

    expect(await initializer.updateContentFromArchive(release), isTrue);

    final preserved = await isar.learningResourceModels
        .filter()
        .uuidEqualTo(uuid)
        .findFirst();

    expect(preserved, isNotNull);
    expect(preserved!.id, local.id);
    expect(preserved.title, 'My private local title');
    expect(preserved.originalFileName, 'private-local.pdf');
    expect(preserved.relativeFilePath, relativePath);
    expect(preserved.fileSizeBytes, localBytes.length);
    expect(await localFile.readAsBytes(), localBytes);
    expect(
      StarterContentLedger(preferences).knownResourceUuids,
      isNot(contains(uuid)),
    );
  });

  test(
      'incremental update does not restore an intentionally deleted starter PDF',
      () async {
    final expected = await loadExpectedPackageUuids();

    expect(await initializer.updateBundledContent(), isTrue);

    final ledger = StarterContentLedger(preferences);
    final resource = (await isar.learningResourceModels.where().findAll())
        .firstWhere((item) =>
            item.relativeFilePath.startsWith('learning_resources/pdfs/'));
    expect(ledger.knownResourceUuids, contains(resource.uuid));

    await storage.deletePdf(resource.relativeFilePath);
    await isar.writeTxn(() async {
      await isar.learningResourceModels.delete(resource.id);
    });
    expect(await ledger.recordDeletionIfStarter(resource.uuid), isTrue);

    expect(await initializer.updateBundledContent(), isTrue);

    final remaining = await isar.learningResourceModels.where().findAll();
    expect(remaining, hasLength(expected['resources']!.length - 1));
    expect(remaining.any((item) => item.uuid == resource.uuid), isFalse);
    expect(
      await File('${tempDir.path}/${resource.relativeFilePath}').exists(),
      isFalse,
    );
    expect(ledger.deletedResourceUuids, contains(resource.uuid));
  });

  test('does not restore the starter library a second time', () async {
    bundledArchiveBytes = buildUnversionedArchive(await loadBundledArchive());
    final pdfUuids = await loadPackagedPdfUuids();
    bundledArchiveBytes = buildArchiveWithResources(pdfUuids);

    expect(await initializer.initializeIfEligible(), isTrue);
    expect(await isar.learningResourceModels.count(), pdfUuids.length);

    expect(await initializer.initializeIfEligible(), isFalse);
    expect(await isar.learningResourceModels.count(), pdfUuids.length);
  });
}
