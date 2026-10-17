import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/citation_model.dart';
import 'package:medvault_app/features/library/data/models/note_model.dart';
import 'package:medvault_app/features/library/data/models/taxonomy_node_model.dart';
import 'package:medvault_app/features/library/data/repositories/curriculum_pack_importer.dart';
import 'package:medvault_shared/medvault_shared.dart';

final _timestamp = DateTime.utc(2026, 1, 1);

SyncMetadata _sync() => SyncMetadata(
      lastModifiedLocal: _timestamp,
      isDirty: false,
      isDeleted: false,
      deviceId: 'test-device',
      syncRevision: 1,
    );

CurriculumPack _validPack({
  String packUuid = 'pack-1',
  String parentUuid = 'subject-1',
  String childUuid = 'topic-1',
  String noteUuid = 'note-1',
  String citationUuid = 'citation-1',
  String noteBody = 'Test body',
}) {
  return CurriculumPack(
    manifest: CurriculumPackManifest(
      formatVersion: currentCurriculumPackFormatVersion,
      packUuid: packUuid,
      version: 1,
      title: 'Test curriculum pack',
    ),
    // Deliberately place the child before its parent.
    taxonomyNodes: [
      CurriculumPackTaxonomyNode(
        uuid: childUuid,
        parentUuid: parentUuid,
        nodeType: 'topic',
        title: 'Example topic',
        slug: 'example-topic',
        sortOrder: 0,
      ),
      CurriculumPackTaxonomyNode(
        uuid: parentUuid,
        nodeType: 'subject',
        title: 'Example subject',
        slug: 'example-subject',
        sortOrder: 0,
      ),
    ],
    citations: [
      CurriculumPackCitation(
        uuid: citationUuid,
        sourceType: 'textbook',
        title: 'Example reference',
      ),
    ],
    notes: [
      CurriculumPackNote(
        uuid: noteUuid,
        topicUuid: childUuid,
        mode: 'detailedNotes',
        title: 'Example note',
        bodyMarkdown: noteBody,
        tags: ['example'],
        citationOrder: [citationUuid],
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
      'medvault_curriculum_import_test_',
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

  test('imports records and resolves taxonomy paths independent of order',
      () async {
    final result = await importer.importPack(_validPack());

    expect(result.taxonomyNodesImported, 2);
    expect(result.citationsImported, 1);
    expect(result.notesImported, 1);

    final parent = await isar.taxonomyNodeModels
        .filter()
        .uuidEqualTo('subject-1')
        .findFirst();
    final child = await isar.taxonomyNodeModels
        .filter()
        .uuidEqualTo('topic-1')
        .findFirst();
    final note =
        await isar.noteModels.filter().uuidEqualTo('note-1').findFirst();
    final citation = await isar.citationModels
        .filter()
        .uuidEqualTo('citation-1')
        .findFirst();

    expect(parent, isNotNull);
    expect(parent!.path, 'subject-1');
    expect(parent.depth, 0);
    expect(parent.curriculumPackUuid, 'pack-1');
    expect(parent.curriculumPackVersion, 1);
    expect(parent.isUserCreated, isFalse);

    expect(child, isNotNull);
    expect(child!.path, 'subject-1/topic-1');
    expect(child.depth, 1);
    expect(child.parentUuid, 'subject-1');
    expect(child.noteCount, 1);

    expect(note, isNotNull);
    expect(note!.bodyMarkdown, 'Test body');
    expect(note.topicUuid, 'topic-1');
    expect(note.citationOrder, ['citation-1']);
    expect(note.isPinned, isFalse);

    expect(citation, isNotNull);
    expect(citation!.title, 'Example reference');
  });

  test('rejects an invalid pack without writing any records', () async {
    final pack = _validPack(noteBody: '');

    await expectLater(
      importer.importPack(pack),
      throwsA(isA<CurriculumPackImportException>()),
    );

    expect(await isar.taxonomyNodeModels.count(), 0);
    expect(await isar.noteModels.count(), 0);
    expect(await isar.citationModels.count(), 0);
  });

  test('rejects an existing taxonomy UUID without partially importing',
      () async {
    await importer.importPack(
      CurriculumPack(
        manifest: CurriculumPackManifest(
          formatVersion: currentCurriculumPackFormatVersion,
          packUuid: 'existing-pack',
          version: 1,
          title: 'Existing pack',
        ),
        taxonomyNodes: [
          CurriculumPackTaxonomyNode(
            uuid: 'existing-node',
            nodeType: 'subject',
            title: 'Existing subject',
            slug: 'existing-subject',
            sortOrder: 0,
          ),
        ],
        citations: [],
        notes: [],
      ),
    );

    final beforeTaxonomyCount = await isar.taxonomyNodeModels.count();

    await expectLater(
      importer.importPack(
        CurriculumPack(
          manifest: CurriculumPackManifest(
            formatVersion: currentCurriculumPackFormatVersion,
            packUuid: 'incoming-pack',
            version: 1,
            title: 'Incoming pack',
          ),
          taxonomyNodes: [
            CurriculumPackTaxonomyNode(
              uuid: 'new-node',
              nodeType: 'subject',
              title: 'New subject',
              slug: 'new-subject',
              sortOrder: 0,
            ),
            CurriculumPackTaxonomyNode(
              uuid: 'existing-node',
              nodeType: 'subject',
              title: 'Conflicting subject',
              slug: 'conflicting-subject',
              sortOrder: 1,
            ),
          ],
          citations: [
            CurriculumPackCitation(
              uuid: 'incoming-citation',
              sourceType: 'textbook',
              title: 'Incoming reference',
            ),
          ],
          notes: [],
        ),
      ),
      throwsA(isA<CurriculumPackImportException>()),
    );

    expect(await isar.taxonomyNodeModels.count(), beforeTaxonomyCount);
    expect(
      await isar.taxonomyNodeModels
          .filter()
          .uuidEqualTo('new-node')
          .findFirst(),
      isNull,
    );
    expect(await isar.citationModels.count(), 0);
  });

  test('rejects duplicate sibling slugs without writing records', () async {
    final pack = _validPack();
    final conflictingPack = CurriculumPack(
      manifest: pack.manifest,
      taxonomyNodes: [
        ...pack.taxonomyNodes,
        CurriculumPackTaxonomyNode(
          uuid: 'subject-2',
          nodeType: 'subject',
          title: 'Another subject',
          slug: 'example-subject',
          sortOrder: 1,
        ),
      ],
      citations: pack.citations,
      notes: pack.notes,
    );

    await expectLater(
      importer.importPack(conflictingPack),
      throwsA(isA<CurriculumPackImportException>()),
    );

    expect(await isar.taxonomyNodeModels.count(), 0);
    expect(await isar.noteModels.count(), 0);
    expect(await isar.citationModels.count(), 0);
  });

  test('rejects duplicate topic and mode combinations without writing records',
      () async {
    final pack = _validPack();
    final conflictingPack = CurriculumPack(
      manifest: pack.manifest,
      taxonomyNodes: pack.taxonomyNodes,
      citations: pack.citations,
      notes: [
        ...pack.notes,
        CurriculumPackNote(
          uuid: 'note-2',
          topicUuid: 'topic-1',
          mode: 'detailedNotes',
          title: 'Another note',
          bodyMarkdown: 'Synthetic test content',
          tags: ['another'],
          citationOrder: ['citation-1'],
        ),
      ],
    );

    await expectLater(
      importer.importPack(conflictingPack),
      throwsA(isA<CurriculumPackImportException>()),
    );

    expect(await isar.taxonomyNodeModels.count(), 0);
    expect(await isar.noteModels.count(), 0);
    expect(await isar.citationModels.count(), 0);
  });

  test('rejects an existing note UUID without modifying existing data',
      () async {
    final pack = _validPack();
    await importer.importPack(pack);

    final conflictingPack = CurriculumPack(
      manifest: CurriculumPackManifest(
        formatVersion: currentCurriculumPackFormatVersion,
        packUuid: 'incoming-note-conflict',
        version: 1,
        title: 'Incoming note conflict',
      ),
      taxonomyNodes: [],
      citations: [],
      notes: [
        CurriculumPackNote(
          uuid: 'note-1',
          topicUuid: 'topic-1',
          mode: 'detailedNotes',
          title: 'Conflicting note title',
          bodyMarkdown: 'Replacement content',
          tags: ['replacement'],
          citationOrder: ['citation-1'],
        ),
      ],
    );

    await expectLater(
      importer.importPack(conflictingPack),
      throwsA(isA<CurriculumPackImportException>()),
    );

    final existingNote = await isar.noteModels
        .filter()
        .uuidEqualTo('note-1')
        .findFirst();

    expect(await isar.noteModels.count(), 1);
    expect(existingNote, isNotNull);
    expect(existingNote!.title, pack.notes.single.title);
    expect(existingNote.bodyMarkdown, pack.notes.single.bodyMarkdown);
    expect(existingNote.tags, pack.notes.single.tags);
    expect(await isar.taxonomyNodeModels.count(), 2);
    expect(await isar.citationModels.count(), 1);
  });

  test('rejects an existing citation UUID without modifying existing data',
      () async {
    final pack = _validPack();
    await importer.importPack(pack);

    final conflictingPack = CurriculumPack(
      manifest: CurriculumPackManifest(
        formatVersion: currentCurriculumPackFormatVersion,
        packUuid: 'incoming-citation-conflict',
        version: 1,
        title: 'Incoming citation conflict',
      ),
      taxonomyNodes: [],
      citations: [
        CurriculumPackCitation(
          uuid: 'citation-1',
          sourceType: 'textbook',
          title: 'Conflicting reference',
          authors: 'Replacement author',
        ),
      ],
      notes: [],
    );

    await expectLater(
      importer.importPack(conflictingPack),
      throwsA(isA<CurriculumPackImportException>()),
    );

    final existingCitation = await isar.citationModels
        .filter()
        .uuidEqualTo('citation-1')
        .findFirst();

    expect(await isar.citationModels.count(), 1);
    expect(existingCitation, isNotNull);
    expect(existingCitation!.title, pack.citations.single.title);
    expect(existingCitation.authors, pack.citations.single.authors);
    expect(await isar.taxonomyNodeModels.count(), 2);
    expect(await isar.noteModels.count(), 1);
  });

}
