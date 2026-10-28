import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/citation_model.dart';
import 'package:medvault_app/features/library/data/models/note_model.dart';
import 'package:medvault_app/features/library/data/models/taxonomy_node_model.dart';
import 'package:medvault_app/features/library/data/repositories/curriculum_pack_exporter.dart';
import 'package:medvault_app/features/library/data/repositories/curriculum_pack_importer.dart';
import 'package:medvault_shared/medvault_shared.dart';

final _timestamp = DateTime.utc(2026, 1, 1);

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: _timestamp,
      isDirty: false,
      isDeleted: false,
      deviceId: 'export-test-device',
      syncRevision: 1,
    );

CurriculumPack _testPack() {
  return CurriculumPack(
    manifest: CurriculumPackManifest(
      formatVersion: currentCurriculumPackFormatVersion,
      packUuid: 'source-pack',
      version: 1,
      title: 'Synthetic Export Test',
      description: 'A test fixture for portable backup verification.',
    ),
    taxonomyNodes: [
      CurriculumPackTaxonomyNode(
        uuid: 'subject-export-test',
        nodeType: 'subject',
        title: 'Synthetic Subject',
        slug: 'synthetic-subject',
        shortDescription: 'Synthetic description',
        iconKey: 'book',
        sortOrder: 2,
      ),
      CurriculumPackTaxonomyNode(
        uuid: 'topic-export-test',
        parentUuid: 'subject-export-test',
        nodeType: 'topic',
        title: 'Synthetic Topic',
        slug: 'synthetic-topic',
        shortDescription: 'Nested synthetic topic',
        iconKey: 'notes',
        sortOrder: 3,
      ),
    ],
    citations: [
      CurriculumPackCitation(
        uuid: 'citation-export-test',
        sourceType: 'textbook',
        title: 'Synthetic Reference',
        authors: 'Test Author',
        publicationYear: 2024,
        pageReference: '10-12',
        url: 'https://example.com/test-reference',
      ),
    ],
    notes: [
      CurriculumPackNote(
        uuid: 'note-export-test',
        topicUuid: 'topic-export-test',
        mode: 'quickReview',
        title: 'Synthetic Note',
        bodyMarkdown: 'Synthetic placeholder body for export testing.',
        tags: ['synthetic', 'backup-test'],
        citationOrder: ['citation-export-test'],
      ),
    ],
  );
}

void main() {
  late Isar isar;
  late Directory tempDir;
  late CurriculumPackImporter importer;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'medvault_curriculum_export_test_',
    );
    isar = await Isar.open(
      [
        TaxonomyNodeModelSchema,
        NoteModelSchema,
        CitationModelSchema,
      ],
      directory: tempDir.path,
    );
    importer = CurriculumPackImporter(
      isar: isar,
      createSyncMetadata: _sync,
      now: () => _timestamp,
    );
  });

  tearDown(() async {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('exports portable content with relationships and metadata intact',
      () async {
    await importer.importPack(_testPack());

    final pack = await CurriculumPackExporter(
      isar: isar,
      generatePackUuid: () => 'generated-backup-id',
    ).exportPack();

    expect(pack.manifest.formatVersion, currentCurriculumPackFormatVersion);
    expect(pack.manifest.packUuid, 'generated-backup-id');
    expect(pack.manifest.version, 1);
    expect(pack.manifest.title, 'Clinical Crumbs Full Backup');

    expect(pack.taxonomyNodes, hasLength(2));
    final subject = pack.taxonomyNodes.singleWhere(
      (node) => node.uuid == 'subject-export-test',
    );
    final topic = pack.taxonomyNodes.singleWhere(
      (node) => node.uuid == 'topic-export-test',
    );

    expect(subject.nodeType, 'subject');
    expect(subject.parentUuid, isNull);
    expect(subject.shortDescription, 'Synthetic description');
    expect(subject.iconKey, 'book');
    expect(subject.sortOrder, 2);

    expect(topic.nodeType, 'topic');
    expect(topic.parentUuid, 'subject-export-test');
    expect(topic.slug, 'synthetic-topic');
    expect(topic.sortOrder, 3);

    expect(pack.notes, hasLength(1));
    final note = pack.notes.single;
    expect(note.uuid, 'note-export-test');
    expect(note.topicUuid, 'topic-export-test');
    expect(note.mode, 'quickReview');
    expect(note.bodyMarkdown, 'Synthetic placeholder body for export testing.');
    expect(note.tags, ['synthetic', 'backup-test']);
    expect(note.citationOrder, ['citation-export-test']);

    expect(pack.citations, hasLength(1));
    final citation = pack.citations.single;
    expect(citation.uuid, 'citation-export-test');
    expect(citation.sourceType, 'textbook');
    expect(citation.title, 'Synthetic Reference');
    expect(citation.authors, 'Test Author');
    expect(citation.publicationYear, 2024);
    expect(citation.pageReference, '10-12');
    expect(citation.url, 'https://example.com/test-reference');

    final validation = const CurriculumPackValidator().validate(pack);
    expect(validation.isValid, isTrue, reason: '${validation.issues}');
  });

  test('export does not change stored record counts or note content',
      () async {
    await importer.importPack(_testPack());

    final taxonomyCountBefore = await isar.taxonomyNodeModels.count();
    final noteCountBefore = await isar.noteModels.count();
    final citationCountBefore = await isar.citationModels.count();
    final noteBefore = await isar.noteModels
        .filter()
        .uuidEqualTo('note-export-test')
        .findFirst();

    await CurriculumPackExporter(
      isar: isar,
      generatePackUuid: () => 'read-only-backup-id',
    ).exportPack();

    expect(await isar.taxonomyNodeModels.count(), taxonomyCountBefore);
    expect(await isar.noteModels.count(), noteCountBefore);
    expect(await isar.citationModels.count(), citationCountBefore);

    final noteAfter = await isar.noteModels
        .filter()
        .uuidEqualTo('note-export-test')
        .findFirst();

    expect(noteAfter, isNotNull);
    expect(noteAfter!.uuid, noteBefore!.uuid);
    expect(noteAfter.title, noteBefore.title);
    expect(noteAfter.bodyMarkdown, noteBefore.bodyMarkdown);
    expect(noteAfter.tags, noteBefore.tags);
    expect(noteAfter.citationOrder, noteBefore.citationOrder);
  });

  test('exported JSON can be decoded and validated again', () async {
    await importer.importPack(_testPack());

    final exported = await CurriculumPackExporter(
      isar: isar,
      generatePackUuid: () => 'json-round-trip-backup',
    ).exportPack();

    final decoded = CurriculumPack.fromJson(exported.toJson());
    final validation = const CurriculumPackValidator().validate(decoded);

    expect(validation.isValid, isTrue, reason: '${validation.issues}');
    expect(decoded.taxonomyNodes, hasLength(2));
    expect(decoded.notes.single.uuid, 'note-export-test');
    expect(decoded.citations.single.uuid, 'citation-export-test');
  });

  test('backup restores into a separate empty database', () async {
    await importer.importPack(_testPack());

    final exported = await CurriculumPackExporter(
      isar: isar,
      generatePackUuid: () => 'restore-test-backup',
    ).exportPack();

    // Exercise the same JSON serialization boundary as a saved backup file.
    final json = exported.toJson();
    final restoredPack = CurriculumPack.fromJson(json);
    final validation = const CurriculumPackValidator().validate(restoredPack);
    expect(validation.isValid, isTrue, reason: '${validation.issues}');

    final restoreDir = await Directory.systemTemp.createTemp(
      'medvault_curriculum_restore_test_',
    );
    Isar? restoreIsar;

    try {
      restoreIsar = await Isar.open(
        [
          TaxonomyNodeModelSchema,
          NoteModelSchema,
          CitationModelSchema,
        ],
        directory: restoreDir.path,
        name: 'medvault-restore-test',
      );

      final restoreImporter = CurriculumPackImporter(
        isar: restoreIsar,
        createSyncMetadata: _sync,
        now: () => _timestamp,
      );

      final result = await restoreImporter.importPack(restoredPack);

      expect(result.taxonomyNodesImported, 2);
      expect(result.notesImported, 1);
      expect(result.citationsImported, 1);

      final subject = await restoreIsar.taxonomyNodeModels
          .filter()
          .uuidEqualTo('subject-export-test')
          .findFirst();
      final topic = await restoreIsar.taxonomyNodeModels
          .filter()
          .uuidEqualTo('topic-export-test')
          .findFirst();
      final note = await restoreIsar.noteModels
          .filter()
          .uuidEqualTo('note-export-test')
          .findFirst();
      final citation = await restoreIsar.citationModels
          .filter()
          .uuidEqualTo('citation-export-test')
          .findFirst();

      expect(subject, isNotNull);
      expect(subject!.path, 'subject-export-test');
      expect(topic, isNotNull);
      expect(topic!.parentUuid, 'subject-export-test');
      expect(topic.path, 'subject-export-test/topic-export-test');

      expect(note, isNotNull);
      expect(note!.topicUuid, topic.uuid);
      expect(note.mode.name, 'quickReview');
      expect(note.title, 'Synthetic Note');
      expect(note.bodyMarkdown, 'Synthetic placeholder body for export testing.');
      expect(note.tags, ['synthetic', 'backup-test']);
      expect(note.citationOrder, ['citation-export-test']);

      expect(citation, isNotNull);
      expect(citation!.title, 'Synthetic Reference');
      expect(citation.authors, 'Test Author');
      expect(citation.publicationYear, 2024);

      expect(await restoreIsar.taxonomyNodeModels.count(), 2);
      expect(await restoreIsar.noteModels.count(), 1);
      expect(await restoreIsar.citationModels.count(), 1);
    } finally {
      if (restoreIsar != null) {
        await restoreIsar.close();
      }
      if (await restoreDir.exists()) {
        await restoreDir.delete(recursive: true);
      }
    }
  });

}
