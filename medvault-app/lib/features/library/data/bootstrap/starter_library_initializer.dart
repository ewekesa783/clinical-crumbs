import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'starter_content_ledger.dart';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:medvault_shared/medvault_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/learning_resource_file_storage.dart';
import '../topic_packages/prototype_html_lesson_archive_reader.dart';
import '../../../../core/sync/sync_metadata.dart';
import '../models/bookmark_model.dart';
import '../models/citation_model.dart';
import '../models/history_model.dart';
import '../models/learning_resource_model.dart';
import '../models/note_model.dart';
import '../models/taxonomy_node_model.dart';
import '../models/taxonomy_node_mapper.dart';
import '../../domain/entities/taxonomy_node.dart';

/// Safely restores the bundled starter PDFs into a clean/default-only library.
///
/// Taxonomy is validated but never inserted or modified by this class.
class StarterLibraryInitializer {
  StarterLibraryInitializer({
    required Isar isar,
    required LearningResourceFileStorage fileStorage,
    required SharedPreferences preferences,
    required SyncMetadata Function() createSyncMetadata,
    required DateTime Function() now,
    Future<Uint8List> Function()? assetLoader,
  })  : _isar = isar,
        _fileStorage = fileStorage,
        _preferences = preferences,
        _createSyncMetadata = createSyncMetadata,
        _now = now,
        _assetLoader = assetLoader ?? _loadAsset;

  static const assetPath = 'assets/bootstrap/medvault-starter-library.zip';
  static const completionKey = 'medvault_starter_library_bootstrap_v1_complete';

  final Isar _isar;
  final LearningResourceFileStorage _fileStorage;
  final SharedPreferences _preferences;
  final SyncMetadata Function() _createSyncMetadata;
  final DateTime Function() _now;
  final Future<Uint8List> Function() _assetLoader;

  static Future<Uint8List> _loadAsset() async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
  }

  /// Returns true only when the starter resources were restored successfully.
  ///
  /// A populated or incompatible library is left untouched and returns false.
  Future<bool> initializeIfEligible() async {
    if (_preferences.getBool(completionKey) == true) {
      return false;
    }

    if (!await _isEmptyOfUserContent()) {
      return false;
    }

    final existingTaxonomy = await _isar.taxonomyNodeModels.where().findAll();

    final Uint8List zipBytes;
    try {
      zipBytes = await _assetLoader();
    } catch (_) {
      return false;
    }

    final _ValidatedBackup backup;
    try {
      backup = _validateArchive(zipBytes);
    } catch (_) {
      return false;
    }

    if (!_taxonomyIsCompatible(existingTaxonomy, backup.nodes)) {
      return false;
    }

    final missingTaxonomyModels = _buildMissingTaxonomyModels(
      existingTaxonomy,
      backup.nodes,
      backup.packUuid,
      backup.packVersion,
    );

    final taxonomyUuids = backup.nodes.map((node) => node.uuid).toSet();

    if (backup.resources.any(
      (resource) => !taxonomyUuids.contains(resource.topicUuid),
    )) {
      return false;
    }

    // Check every destination before writing any file.
    for (final resource in backup.resources) {
      try {
        final file = await _fileStorage.resolvePdf(
          'learning_resources/pdfs/${resource.uuid}.pdf',
        );
        if (await file.exists()) return false;
      } on Exception {
        // A missing file is expected. resolvePdf throws when it is absent.
      }
    }

    // Restore only after all archive, metadata, taxonomy and eligibility
    // checks have passed. Never overwrite a destination file.
    final createdPaths = <String>[];
    try {
      for (final resource in backup.resources) {
        final relativePath = await _fileStorage.restorePdf(
          uuid: resource.uuid,
          bytes: resource.bytes,
        );
        createdPaths.add(relativePath);
        resource.model.relativeFilePath = relativePath;
      }

      await _isar.writeTxn(() async {
        if (missingTaxonomyModels.isNotEmpty) {
          await _isar.taxonomyNodeModels.putAll(missingTaxonomyModels);
        }
        await _isar.learningResourceModels.putAll(
          backup.resources.map((resource) => resource.model).toList(),
        );
      });
    } catch (_) {
      for (final path in createdPaths.reversed) {
        try {
          await _fileStorage.deletePdf(path);
        } catch (_) {
          // Preserve the original failure; never delete files we didn't create.
        }
      }
      return false;
    }

    // Record starter UUIDs so intentional deletions can be preserved across
    // subsequent content releases.
    try {
      await StarterContentLedger(_preferences).registerBundledResources(
        backup.resources.map((resource) => resource.uuid),
      );
    } catch (_) {
      // Do not undo a completed installation if the ledger write fails.
    }

    // The records themselves also prevent a retry if writing this preference
    // fails. Never roll back a completed database transaction for this marker.
    if (backup.contentVersion != null) {
      try {
        await StarterContentLedger(_preferences)
            .recordInstalledContentVersion(backup.contentVersion!);
      } catch (_) {
        // Installed records remain authoritative if the version marker fails.
      }
    }

    try {
      await _preferences.setBool(completionKey, true);
    } catch (_) {
      // A later launch will see the restored resources and safely skip.
    }

    return true;
  }

  /// Adds newly bundled content to an existing library without overwriting
  /// existing resources or restoring resources recorded as intentionally
  /// deleted.
  Future<bool> updateBundledContent() async {
    final Uint8List zipBytes;
    try {
      zipBytes = await _assetLoader();
    } catch (_) {
      return false;
    }

    return updateContentFromArchive(zipBytes);
  }

  /// Validates and safely installs a versioned content archive.
  ///
  /// This shares the same installation path as bundled updates and is intended
  /// for explicit, user-initiated remote updates.
  Future<bool> updateContentFromArchive(
    Uint8List zipBytes, {
    Map<String, dynamic>? expectedManifest,
  }) async {
    final _ValidatedBackup backup;
    try {
      backup = _validateArchive(zipBytes);
    } catch (_) {
      return false;
    }

    if (expectedManifest != null) {
      final actualManifest = backup.contentManifest;
      if (actualManifest == null ||
          jsonEncode(_canonicalizeJson(actualManifest)) !=
              jsonEncode(_canonicalizeJson(expectedManifest))) {
        return false;
      }
    }

    final ledger = StarterContentLedger(_preferences);
    // Snapshot ownership before inspecting the incoming release. Incoming
    // UUIDs must not become trusted until the update has been accepted.
    final knownResourceUuids = ledger.knownResourceUuids;
    final deletedUuids = ledger.deletedResourceUuids;
    final installedContentVersion = ledger.installedContentVersion;
    if (backup.contentVersion != null &&
        installedContentVersion != null &&
        backup.contentVersion! <= installedContentVersion) {
      return false;
    }

    final existingTaxonomy = await _isar.taxonomyNodeModels.where().findAll();
    if (!_taxonomyIsCompatibleForUpdate(existingTaxonomy, backup.nodes)) {
      return false;
    }

    final missingTaxonomyModels = _buildMissingTaxonomyModels(
      existingTaxonomy,
      backup.nodes,
      backup.packUuid,
      backup.packVersion,
    );

    final availableTopicUuids = {
      ...existingTaxonomy.map((node) => node.uuid),
      ...backup.nodes.map((node) => node.uuid),
    };
    if (backup.resources.any(
      (resource) => !availableTopicUuids.contains(resource.topicUuid),
    )) {
      return false;
    }

    final existingResources =
        await _isar.learningResourceModels.where().findAll();
    final existingResourcesByUuid = {
      for (final resource in existingResources) resource.uuid: resource,
    };

    final toReplace =
        <({_ValidatedResource incoming, LearningResourceModel existing})>[];
    final candidates = <_ValidatedResource>[];
    for (final resource in backup.resources) {
      if (deletedUuids.contains(resource.uuid)) continue;

      final existing = existingResourcesByUuid[resource.uuid];
      if (existing == null) {
        candidates.add(resource);
      } else if (knownResourceUuids.contains(resource.uuid)) {
        toReplace.add((incoming: resource, existing: existing));
      }
      // Existing resources without prior ledger ownership are deliberately
      // left untouched, even when the incoming archive has the same UUID.
    }

    // Never overwrite an orphaned PDF whose database record is missing.
    final toInstall = <_ValidatedResource>[];
    for (final resource in candidates) {
      if (!resource.isHtmlLesson) {
        final relativePath = 'learning_resources/pdfs/${resource.uuid}.pdf';
        try {
          final file = await _fileStorage.resolvePdf(relativePath);
          if (await file.exists()) continue;
        } on Exception {
          // No managed destination exists, so installation can proceed.
        }
      }
      toInstall.add(resource);
    }

    final createdPaths = <String>[];
    final replacedPdfs = <({String path, Uint8List bytes})>[];
    final oldMetadata = <({
      LearningResourceModel model,
      String topicUuid,
      String title,
      String originalFileName,
      String relativeFilePath,
      int fileSizeBytes,
      DateTime importedAt
    })>[];
    try {
      for (final resource in toInstall) {
        final relativePath = resource.isHtmlLesson
            ? await _fileStorage.importHtmlLessonPackageBytes(resource.bytes)
            : await _fileStorage.restorePdf(
                uuid: resource.uuid,
                bytes: resource.bytes,
              );
        createdPaths.add(relativePath);
        resource.model.relativeFilePath = relativePath;
      }

      for (final replacement in toReplace) {
        final incoming = replacement.incoming;
        final existing = replacement.existing;
        final oldPath = existing.relativeFilePath;

        oldMetadata.add((
          model: existing,
          topicUuid: existing.topicUuid,
          title: existing.title,
          originalFileName: existing.originalFileName,
          relativeFilePath: existing.relativeFilePath,
          fileSizeBytes: existing.fileSizeBytes,
          importedAt: existing.importedAt,
        ));

        if (incoming.isHtmlLesson) {
          final oldFile = await _fileStorage.resolveHtmlLessonPackage(oldPath);
          final oldBytes = await oldFile.readAsBytes();
          if (!_bytesEqual(oldBytes, incoming.bytes)) {
            final newPath = await _fileStorage.importHtmlLessonPackageBytes(
              incoming.bytes,
            );
            createdPaths.add(newPath);
            existing.relativeFilePath = newPath;
          }
        } else {
          final oldFile = await _fileStorage.resolvePdf(oldPath);
          final oldBytes = Uint8List.fromList(await oldFile.readAsBytes());
          if (!_bytesEqual(oldBytes, incoming.bytes)) {
            replacedPdfs.add((path: oldPath, bytes: oldBytes));
            await _fileStorage.replaceManagedPdf(
              relativeFilePath: oldPath,
              bytes: incoming.bytes,
            );
          }
        }

        existing
          ..topicUuid = incoming.topicUuid
          ..title = incoming.model.title
          ..originalFileName = incoming.model.originalFileName
          ..fileSizeBytes = incoming.bytes.length;
      }

      await _isar.writeTxn(() async {
        if (missingTaxonomyModels.isNotEmpty) {
          await _isar.taxonomyNodeModels.putAll(missingTaxonomyModels);
        }
        if (toInstall.isNotEmpty) {
          await _isar.learningResourceModels.putAll(
            toInstall.map((resource) => resource.model).toList(),
          );
        }
        if (toReplace.isNotEmpty) {
          await _isar.learningResourceModels.putAll(
            toReplace.map((replacement) => replacement.existing).toList(),
          );
        }
      });
    } catch (_) {
      // Restore any PDF bytes changed before the database transaction failed.
      for (final replacement in replacedPdfs.reversed) {
        try {
          await _fileStorage.replaceManagedPdf(
            relativeFilePath: replacement.path,
            bytes: replacement.bytes,
          );
        } catch (_) {
          // Keep attempting other rollbacks.
        }
      }

      // Restore in-memory metadata and persisted records if they were changed.
      for (final previous in oldMetadata) {
        previous.model
          ..topicUuid = previous.topicUuid
          ..title = previous.title
          ..originalFileName = previous.originalFileName
          ..relativeFilePath = previous.relativeFilePath
          ..fileSizeBytes = previous.fileSizeBytes
          ..importedAt = previous.importedAt;
      }
      try {
        if (oldMetadata.isNotEmpty) {
          await _isar.writeTxn(() async {
            await _isar.learningResourceModels.putAll(
              oldMetadata.map((previous) => previous.model).toList(),
            );
          });
        }
      } catch (_) {
        // Preserve the original update failure.
      }

      for (final path in createdPaths.reversed) {
        try {
          if (path.startsWith('learning_resources/html_lessons/')) {
            await _fileStorage.deleteHtmlLessonPackage(path);
          } else {
            await _fileStorage.deletePdf(path);
          }
        } catch (_) {
          // Never delete pre-existing files during rollback.
        }
      }
      return false;
    }

    // Delete old HTML packages only when a replacement changed the path.
    for (final replacement in toReplace) {
      if (!replacement.incoming.isHtmlLesson) continue;
      final previous = oldMetadata.firstWhere(
        (previous) => previous.model.uuid == replacement.existing.uuid,
      );
      if (replacement.existing.relativeFilePath == previous.relativeFilePath) {
        continue;
      }
      try {
        await _fileStorage.deleteHtmlLessonPackage(previous.relativeFilePath);
      } catch (_) {
        // The updated resource remains usable; orphan cleanup can happen later.
      }
    }

    try {
      // Claim only resources actually installed by this update or
      // replaced under ownership already established by an earlier release.
      // Matching UUIDs alone must never claim an existing local resource.
      await ledger.registerBundledResources(
        <String>{
          ...toInstall.map((resource) => resource.uuid),
          ...toReplace.map((replacement) => replacement.incoming.uuid),
        }.where((uuid) => !deletedUuids.contains(uuid)),
      );
    } catch (_) {
      // Content is installed; do not undo it if ledger persistence fails.
    }

    if (backup.contentVersion != null) {
      try {
        await ledger.recordInstalledContentVersion(backup.contentVersion!);
      } catch (_) {
        // Do not undo installed content if only the version marker fails.
      }
    }

    return true;
  }

  bool _bytesEqual(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  bool _taxonomyIsCompatibleForUpdate(
    List<TaxonomyNodeModel> existing,
    List<CurriculumPackTaxonomyNode> bundled,
  ) {
    final bundledByUuid = {for (final node in bundled) node.uuid: node};

    for (final local in existing) {
      final source = bundledByUuid[local.uuid];
      if (source == null) continue;

      if (local.isUserCreated ||
          local.parentUuid != source.parentUuid ||
          local.nodeType.name != source.nodeType ||
          local.title != source.title ||
          local.slug != source.slug ||
          local.shortDescription != source.shortDescription ||
          local.iconKey != source.iconKey ||
          local.sortOrder != source.sortOrder) {
        return false;
      }
    }

    return true;
  }

  Future<bool> _isEmptyOfUserContent() async {
    return await _isar.noteModels.count() == 0 &&
        await _isar.citationModels.count() == 0 &&
        await _isar.bookmarkModels.count() == 0 &&
        await _isar.historyModels.count() == 0 &&
        await _isar.learningResourceModels.count() == 0;
  }

  bool _taxonomyIsCompatible(
    List<TaxonomyNodeModel> existing,
    List<CurriculumPackTaxonomyNode> bundled,
  ) {
    final byUuid = {
      for (final node in bundled) node.uuid: node,
    };

    for (final local in existing) {
      final source = byUuid[local.uuid];
      if (source == null ||
          local.isUserCreated ||
          local.parentUuid != source.parentUuid ||
          local.nodeType.name != source.nodeType ||
          local.title != source.title ||
          local.slug != source.slug ||
          local.shortDescription != source.shortDescription ||
          local.iconKey != source.iconKey ||
          local.sortOrder != source.sortOrder) {
        return false;
      }
    }

    return true;
  }

  List<TaxonomyNodeModel> _buildMissingTaxonomyModels(
    List<TaxonomyNodeModel> existing,
    List<CurriculumPackTaxonomyNode> bundled,
    String packUuid,
    int packVersion,
  ) {
    final bundledByUuid = {for (final node in bundled) node.uuid: node};
    final existingByUuid = {for (final node in existing) node.uuid: node};
    final pathCache = <String, String>{};
    final depthCache = <String, int>{};

    String pathFor(String uuid) {
      final cached = pathCache[uuid];
      if (cached != null) return cached;

      final local = existingByUuid[uuid];
      if (local != null) {
        pathCache[uuid] = local.path;
        return local.path;
      }

      final source = bundledByUuid[uuid]!;
      final parentUuid = source.parentUuid;
      final path = parentUuid == null
          ? source.uuid
          : '${pathFor(parentUuid)}/${source.uuid}';
      pathCache[uuid] = path;
      return path;
    }

    int depthFor(String uuid) {
      final cached = depthCache[uuid];
      if (cached != null) return cached;

      final local = existingByUuid[uuid];
      if (local != null) {
        depthCache[uuid] = local.depth;
        return local.depth;
      }

      final source = bundledByUuid[uuid]!;
      final parentUuid = source.parentUuid;
      final depth = parentUuid == null ? 0 : depthFor(parentUuid) + 1;
      depthCache[uuid] = depth;
      return depth;
    }

    final timestamp = _now();
    final missing = <TaxonomyNodeModel>[];

    for (final source in bundled) {
      if (existingByUuid.containsKey(source.uuid)) continue;

      final node = TaxonomyNode(
        uuid: source.uuid,
        parentUuid: source.parentUuid,
        path: pathFor(source.uuid),
        depth: depthFor(source.uuid),
        nodeType: NodeType.values.byName(source.nodeType),
        title: source.title,
        slug: source.slug,
        shortDescription: source.shortDescription,
        iconKey: source.iconKey,
        sortOrder: source.sortOrder,
        noteCount: 0,
        curriculumPackUuid: packUuid,
        curriculumPackVersion: packVersion,
        isUserCreated: false,
        createdAt: timestamp,
        updatedAt: timestamp,
        sync: _createSyncMetadata(),
      );
      missing.add(TaxonomyNodeMapper.toModel(node));
    }

    return missing;
  }

  dynamic _canonicalizeJson(dynamic value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return <String, dynamic>{
        for (final key in keys) key: _canonicalizeJson(value[key]),
      };
    }
    if (value is List) {
      return value.map(_canonicalizeJson).toList();
    }
    return value;
  }

  int _validateContentManifest({
    required Map<String, ArchiveFile> files,
    required Map<String, dynamic> packJson,
    required String packUuid,
    required int packVersion,
    required List<_ValidatedResource> resources,
  }) {
    final manifestFile = files['content-manifest.json']!;
    final decoded = jsonDecode(
      utf8.decode(manifestFile.content as List<int>),
    );
    if (decoded is! Map) {
      throw const FormatException('Invalid content manifest.');
    }
    final manifest = Map<String, dynamic>.from(decoded);

    final schemaVersion = manifest['schemaVersion'];
    final contentVersion = manifest['contentVersion'];
    if (schemaVersion != 1 ||
        contentVersion is! int ||
        contentVersion < 1 ||
        manifest['sourcePackUuid'] != packUuid ||
        manifest['sourcePackVersion'] != packVersion) {
      throw const FormatException('Invalid content manifest version or pack.');
    }

    final rawTaxonomy = packJson['taxonomyNodes'];
    final manifestTaxonomy = manifest['taxonomy'];
    final manifestResources = manifest['resources'];
    if (rawTaxonomy is! List ||
        manifestTaxonomy is! List ||
        manifestResources is! List) {
      throw const FormatException('Invalid manifest content lists.');
    }

    final taxonomyChecksums = <String, String>{};
    for (final value in rawTaxonomy) {
      if (value is! Map) {
        throw const FormatException('Invalid packaged taxonomy node.');
      }
      final node = Map<String, dynamic>.from(value);
      final uuid = node['uuid'];
      if (uuid is! String || taxonomyChecksums.containsKey(uuid)) {
        throw const FormatException('Missing or duplicate taxonomy UUID.');
      }
      taxonomyChecksums[uuid] = sha256
          .convert(utf8.encode(jsonEncode(_canonicalizeJson(node))))
          .toString();
    }

    final declaredTaxonomy = <String, String>{};
    for (final value in manifestTaxonomy) {
      if (value is! Map) {
        throw const FormatException('Invalid manifest taxonomy entry.');
      }
      final entry = Map<String, dynamic>.from(value);
      final uuid = entry['uuid'];
      final checksum = entry['sha256'];
      if (uuid is! String ||
          checksum is! String ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum) ||
          declaredTaxonomy.containsKey(uuid)) {
        throw const FormatException(
            'Invalid or duplicate manifest taxonomy entry.');
      }
      declaredTaxonomy[uuid] = checksum;
    }

    if (declaredTaxonomy.length != taxonomyChecksums.length ||
        taxonomyChecksums.entries.any(
          (entry) => declaredTaxonomy[entry.key] != entry.value,
        )) {
      throw const FormatException('Taxonomy manifest checksum mismatch.');
    }

    final resourcesByUuid = <String, _ValidatedResource>{
      for (final resource in resources) resource.uuid: resource,
    };
    final declaredResources = <String, Map<String, dynamic>>{};

    for (final value in manifestResources) {
      if (value is! Map) {
        throw const FormatException('Invalid manifest resource entry.');
      }
      final entry = Map<String, dynamic>.from(value);
      final uuid = entry['uuid'];
      final topicUuid = entry['topicUuid'];
      final title = entry['title'];
      final archivePath = entry['archivePath'];
      final fileSize = entry['fileSizeBytes'];
      final checksum = entry['sha256'];

      if (uuid is! String ||
          topicUuid is! String ||
          title is! String ||
          archivePath is! String ||
          fileSize is! int ||
          checksum is! String ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum) ||
          declaredResources.containsKey(uuid)) {
        throw const FormatException(
            'Invalid or duplicate manifest resource entry.');
      }
      declaredResources[uuid] = entry;
    }

    if (declaredResources.length != resourcesByUuid.length) {
      throw const FormatException('Resource manifest entry count mismatch.');
    }

    for (final resource in resources) {
      final entry = declaredResources[resource.uuid];
      final actualChecksum = sha256.convert(resource.bytes).toString();
      if (entry == null ||
          entry['topicUuid'] != resource.topicUuid ||
          entry['title'] != resource.model.title ||
          entry['archivePath'] != resource.archivePath ||
          entry['fileSizeBytes'] != resource.bytes.length ||
          entry['sha256'] != actualChecksum) {
        throw const FormatException(
            'Resource manifest checksum or metadata mismatch.');
      }
    }

    return contentVersion;
  }

  _ValidatedBackup _validateArchive(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final files = <String, ArchiveFile>{};

    for (final entry in archive.files) {
      if (!entry.isFile ||
          entry.name.startsWith('/') ||
          entry.name.contains(r'\') ||
          entry.name.split('/').any(
                (segment) =>
                    segment.isEmpty || segment == '.' || segment == '..',
              ) ||
          files.containsKey(entry.name)) {
        throw const FormatException('Invalid or duplicate ZIP entry.');
      }
      files[entry.name] = entry;
    }

    const requiredPaths = {
      'curriculum-pack.json',
      'resources/metadata.json',
    };

    if (!files.keys.toSet().containsAll(requiredPaths)) {
      throw const FormatException(
          'Required starter archive files are missing.');
    }

    Map<String, dynamic> decodeObject(String path) {
      final decoded = jsonDecode(
        utf8.decode(files[path]!.content as List<int>),
      );
      if (decoded is! Map) {
        throw FormatException('$path must contain a JSON object.');
      }
      return Map<String, dynamic>.from(decoded);
    }

    final packJson = decodeObject('curriculum-pack.json');
    final pack = CurriculumPack.fromJson(packJson);
    if (!const CurriculumPackValidator().validate(pack).isValid ||
        pack.notes.isNotEmpty ||
        pack.citations.isNotEmpty) {
      throw const FormatException('Invalid starter curriculum pack.');
    }

    final metadataFile = files['resources/metadata.json']!;
    final decodedMetadata = jsonDecode(
      utf8.decode(metadataFile.content as List<int>),
    );
    if (decodedMetadata is! List) {
      throw const FormatException('Invalid starter resource metadata.');
    }

    final resources = <_ValidatedResource>[];
    final seenUuids = <String>{};
    final seenPaths = <String>{};

    for (final value in decodedMetadata) {
      if (value is! Map) {
        throw const FormatException('Invalid resource metadata entry.');
      }
      final item = Map<String, dynamic>.from(value);

      final uuid = item['uuid'];
      final topicUuid = item['topicUuid'];
      final title = item['title'];
      final fileName = item['originalFileName'];
      final fileSize = item['fileSizeBytes'];
      final importedAtValue = item['importedAt'];
      final archivePath = item['archivePath'];

      if (uuid is! String ||
          !RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
            r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          ).hasMatch(uuid) ||
          topicUuid is! String ||
          title is! String ||
          title.trim().isEmpty ||
          fileName is! String ||
          fileName.trim().isEmpty ||
          fileName.contains('/') ||
          fileName.contains(r'\') ||
          fileSize is! int ||
          fileSize < 5 ||
          importedAtValue is! String ||
          (archivePath != 'resources/pdfs/$uuid.pdf' &&
              archivePath != 'resources/html_lessons/$uuid.zip') ||
          !seenUuids.add(uuid.toLowerCase()) ||
          !seenPaths.add(archivePath)) {
        throw const FormatException('Invalid or duplicate resource metadata.');
      }

      final isHtmlLesson = archivePath == 'resources/html_lessons/$uuid.zip';
      final archiveFile = files[archivePath];
      if (archiveFile == null) {
        throw FormatException(
          isHtmlLesson
              ? 'An HTML lesson package is missing.'
              : 'A resource PDF is missing.',
        );
      }

      final resourceBytes = Uint8List.fromList(
        archiveFile.content as List<int>,
      );
      if (resourceBytes.length != fileSize || resourceBytes.length < 5) {
        throw const FormatException('Invalid resource bytes or file size.');
      }

      if (isHtmlLesson) {
        const PrototypeHtmlLessonArchiveReader().read(resourceBytes);
      } else if (resourceBytes[0] != 0x25 ||
          resourceBytes[1] != 0x50 ||
          resourceBytes[2] != 0x44 ||
          resourceBytes[3] != 0x46 ||
          resourceBytes[4] != 0x2D) {
        throw const FormatException('Invalid PDF bytes or file size.');
      }

      final importedAt = DateTime.tryParse(importedAtValue);
      if (importedAt == null) {
        throw const FormatException('Invalid resource timestamp.');
      }

      final model = LearningResourceModel()
        ..uuid = uuid
        ..topicUuid = topicUuid
        ..title = title
        ..originalFileName = fileName
        ..relativeFilePath = ''
        ..fileSizeBytes = fileSize
        ..importedAt = importedAt;

      resources.add(
        _ValidatedResource(
          uuid: uuid,
          topicUuid: topicUuid,
          bytes: resourceBytes,
          archivePath: archivePath,
          isHtmlLesson: isHtmlLesson,
          model: model,
        ),
      );
    }

    int? contentVersion;
    if (files.containsKey('content-manifest.json')) {
      contentVersion = _validateContentManifest(
        files: files,
        packJson: packJson,
        packUuid: pack.manifest.packUuid,
        packVersion: pack.manifest.version,
        resources: resources,
      );
    }

    final expectedArchivePaths = {
      ...requiredPaths,
      ...seenPaths,
      if (files.containsKey('content-manifest.json')) 'content-manifest.json',
    };
    if (files.keys.toSet().difference(expectedArchivePaths).isNotEmpty ||
        !files.keys.toSet().containsAll(expectedArchivePaths)) {
      throw const FormatException(
          'Unexpected or unreferenced starter archive contents.');
    }

    final manifestFile = files['content-manifest.json'];
    final Map<String, dynamic>? contentManifest;
    if (manifestFile == null) {
      contentManifest = null;
    } else {
      final decodedManifest = jsonDecode(
        utf8.decode(manifestFile.content as List<int>),
      );
      contentManifest = Map<String, dynamic>.from(decodedManifest as Map);
    }

    return _ValidatedBackup(
      nodes: pack.taxonomyNodes,
      resources: resources,
      packUuid: pack.manifest.packUuid,
      packVersion: pack.manifest.version,
      contentVersion: contentVersion,
      contentManifest: contentManifest,
    );
  }
}

class _ValidatedBackup {
  const _ValidatedBackup({
    required this.nodes,
    required this.resources,
    required this.packUuid,
    required this.packVersion,
    required this.contentVersion,
    required this.contentManifest,
  });

  final List<CurriculumPackTaxonomyNode> nodes;
  final List<_ValidatedResource> resources;
  final String packUuid;
  final int packVersion;
  final int? contentVersion;
  final Map<String, dynamic>? contentManifest;
}

class _ValidatedResource {
  const _ValidatedResource({
    required this.uuid,
    required this.topicUuid,
    required this.bytes,
    required this.archivePath,
    required this.isHtmlLesson,
    required this.model,
  });

  final String uuid;
  final String topicUuid;
  final Uint8List bytes;
  final String archivePath;
  final bool isHtmlLesson;
  final LearningResourceModel model;
}
