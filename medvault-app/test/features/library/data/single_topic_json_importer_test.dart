import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/core/sync/sync_metadata.dart';
import 'package:medvault_app/features/library/data/models/note_model.dart';
import 'package:medvault_app/features/library/data/models/taxonomy_node_mapper.dart';
import 'package:medvault_app/features/library/data/models/taxonomy_node_model.dart';
import 'package:medvault_app/features/library/data/repositories/single_topic_json_importer.dart';
import 'package:medvault_app/features/library/domain/entities/note.dart';
import 'package:medvault_app/features/library/domain/entities/taxonomy_node.dart';

void main() {
  late Isar isar;
  late Directory tempDir;
  late TaxonomyNode destination;
  var uuidCounter = 0;

  SyncMetadata createSyncMetadata() => SyncMetadata(
        remoteId: null,
        lastModifiedLocal: DateTime.utc(2026, 1, 1),
        lastSyncedAt: null,
        isDirty: true,
        isDeleted: false,
        deviceId: 'single-topic-json-import-test',
        syncRevision: 1,
      );

  Map<String, dynamic> sampleDocument() => {
        'id': 'surgery-hernias',
        'title': 'Hernias',
        'rotation': 'Surgery',
        'source': 'Handwritten class notes',
        'definition': {
          'text': 'Protrusion through a weakness in a containing wall.',
          'highlights': [
            {
              'match': 'Protrusion through a weakness',
              'color': 'yellow',
            },
          ],
        },
        'topics': [
          {
            'id': 'inguinal-hernia',
            'title': 'Inguinal hernia',
            'sections': [
              {
                'heading': 'Overview',
                'points': [
                  {
                    'text': 'Contents pass through the inguinal canal.',
                    'marker': 'circled',
                  },
                  {
                    'text': 'A point requiring correction.',
                    'flag': {
                      'status': 'incorrect',
                      'note': 'Check this wording.',
                    },
                  },
                ],
              },
            ],
          },
          {
            'id': 'femoral-hernia',
            'title': 'Femoral hernia',
            'sections': [
              {
                'heading': 'Overview',
                'points': [
                  {'text': 'A sample point.'},
                ],
              },
            ],
          },
        ],
      };

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'single_topic_json_import_test_',
    );
    isar = await Isar.open(
      [
        TaxonomyNodeModelSchema,
        NoteModelSchema,
      ],
      directory: tempDir.path,
    );

    destination = TaxonomyNode(
      uuid: 'destination-system',
      path: 'surgery',
      depth: 0,
      nodeType: NodeType.system,
      title: 'General Surgery',
      slug: 'general-surgery',
      sortOrder: 0,
      noteCount: 0,
      isUserCreated: false,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sync: createSyncMetadata(),
    );

    await isar.writeTxn(() async {
      await isar.taxonomyNodeModels.put(
        TaxonomyNodeMapper.toModel(destination),
      );
    });

    uuidCounter = 0;
  });

  tearDown(() async {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  SingleTopicJsonImporter createImporter() => SingleTopicJsonImporter(
        isar: isar,
        generateUuid: () => 'generated-uuid-${++uuidCounter}',
        createSyncMetadata: createSyncMetadata,
        now: () => DateTime.utc(2026, 1, 1),
      );

  test('imports a parent, introduction, child topics and individual notes',
      () async {
    final result = await createImporter().importDocument(
      destination: destination,
      document: sampleDocument(),
    );

    expect(result.parentTitle, 'Hernias');
    expect(result.childTopicCount, 3);
    expect(result.noteCount, 3);

    final nodes = await isar.taxonomyNodeModels.where().findAll();
    final parent = nodes.singleWhere((node) => node.title == 'Hernias');
    expect(parent.parentUuid, destination.uuid);

    final children = nodes.where((node) => node.parentUuid == parent.uuid);
    expect(children.map((node) => node.title).toSet(), {
      'Introduction',
      'Inguinal hernia',
      'Femoral hernia',
    });
    expect(children.length, 3);

    final notes = await isar.noteModels.where().findAll();
    expect(notes.length, 3);
    expect(
      notes.map((note) => note.topicUuid).toSet(),
      children.map((child) => child.uuid).toSet(),
    );

    final inguinalNode =
        nodes.singleWhere((node) => node.title == 'Inguinal hernia');
    final inguinalNote = notes.singleWhere(
      (note) => note.topicUuid == inguinalNode.uuid,
    );

    expect(inguinalNote.mode, Mode.detailedNotes);
    expect(inguinalNote.bodyMarkdown, contains('Overview'));
    expect(inguinalNote.bodyMarkdown, contains('circled'));
    expect(inguinalNote.bodyMarkdown, contains('Check this wording.'));

    final introductionNode =
        nodes.singleWhere((node) => node.title == 'Introduction');
    final introductionNote = notes.singleWhere(
      (note) => note.topicUuid == introductionNode.uuid,
    );
    expect(
      introductionNote.bodyMarkdown,
      contains('Protrusion through a weakness'),
    );
  });

  test('imports standalone sections JSON as one topic with a direct note',
      () async {
    final document = <String, dynamic>{
      'title': 'Inguinal Hernia',
      'meta': <String, dynamic>{
        'topic': 'Hernias',
        'source': 'Handwritten hernia notes',
        'highlightLegend': <String, dynamic>{
          'yellow': <String, dynamic>{'hex': '#E6F23C'},
        },
      },
      'sections': <dynamic>[
        <String, dynamic>{
          'title': 'Overview',
          'points': <dynamic>[
            <String, dynamic>{
              'html': '<mark data-color="yellow" '
                  'style="background-color:#E6F23C;color:inherit">'
                  'A highlighted phrase</mark> in the notes.',
              'important': true,
            },
          ],
        },
      ],
    };

    final result = await createImporter().importDocument(
      destination: destination,
      document: document,
    );

    expect(result.parentTitle, 'Inguinal Hernia');
    expect(result.childTopicCount, 0);
    expect(result.noteCount, 1);

    final nodes = await isar.taxonomyNodeModels.where().findAll();
    expect(nodes, hasLength(2));
    final topic = nodes.singleWhere(
      (node) => node.title == 'Inguinal Hernia',
    );
    expect(topic.parentUuid, destination.uuid);
    expect(topic.noteCount, 1);

    final notes = await isar.noteModels.where().findAll();
    expect(notes, hasLength(1));
    final note = notes.single;
    expect(note.topicUuid, topic.uuid);
    expect(note.title, 'Inguinal Hernia');
    expect(note.bodyMarkdown, contains('## Overview'));
    expect(note.bodyMarkdown, contains('<mark data-color="yellow"'));
    expect(note.bodyMarkdown, contains('#E6F23C'));
    expect(note.bodyMarkdown, contains('**Important:**'));
    expect(note.bodyMarkdown, contains('A highlighted phrase'));
  });

  test('preserves replacement-format spans, nested points and section notes',
      () async {
    final document = <String, dynamic>{
      'title': 'Inguinal Hernia',
      'meta': <String, dynamic>{
        'source': 'Handwritten hernia notes',
        'format': 'Import-format instructions that should not appear in notes.',
        'highlightLegend': <String, dynamic>{
          'yellow': '#E6F23C',
          'blue': '#59C9F2',
        },
      },
      'sections': <dynamic>[
        <String, dynamic>{
          'title': 'Overview',
          'note': 'Keep this section note.',
          'points': <dynamic>[
            <String, dynamic>{
              'text': 'Alpha highlighted beta',
              'important': true,
              'spans': <dynamic>[
                <String, dynamic>{
                  'text': 'Alpha ',
                  'highlight': null,
                  'highlightColor': null,
                },
                <String, dynamic>{
                  'text': 'highlighted',
                  'highlight': 'yellow',
                  'highlightColor': '#E6F23C',
                },
                <String, dynamic>{
                  'text': ' beta',
                  'highlight': null,
                  'highlightColor': null,
                },
              ],
              'children': <dynamic>[
                <String, dynamic>{
                  'text': 'Nested point',
                  'spans': <dynamic>[
                    <String, dynamic>{
                      'text': 'Nested point',
                      'highlight': 'blue',
                      'highlightColor': '#59C9F2',
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    };

    final result = await createImporter().importDocument(
      destination: destination,
      document: document,
    );

    expect(result.parentTitle, 'Inguinal Hernia');
    expect(result.childTopicCount, 0);
    expect(result.noteCount, 1);

    final nodes = await isar.taxonomyNodeModels.where().findAll();
    final topic = nodes.singleWhere(
      (node) => node.title == 'Inguinal Hernia',
    );
    final notes = await isar.noteModels.where().findAll();
    final note = notes.single;

    expect(note.topicUuid, topic.uuid);
    expect(note.bodyMarkdown, contains('## Overview'));
    expect(note.bodyMarkdown, contains('**Important:**'));
    expect(note.bodyMarkdown, contains('[[CC_HL:#E6F23C]]highlighted[[/CC_HL]]'));
    expect(note.bodyMarkdown, contains('[[CC_HL:#59C9F2]]Nested point[[/CC_HL]]'));
    expect(note.bodyMarkdown, contains('Keep this section note.'));
    expect(note.bodyMarkdown, isNot(contains('Import-format instructions')));
  });

  test('rejects a duplicate import without writing additional records',
      () async {
    final importer = createImporter();

    await importer.importDocument(
      destination: destination,
      document: sampleDocument(),
    );

    final taxonomyCountBefore = await isar.taxonomyNodeModels.count();
    final noteCountBefore = await isar.noteModels.count();

    await expectLater(
      importer.importDocument(
        destination: destination,
        document: sampleDocument(),
      ),
      throwsA(isA<SingleTopicJsonImportException>()),
    );

    expect(await isar.taxonomyNodeModels.count(), taxonomyCountBefore);
    expect(await isar.noteModels.count(), noteCountBefore);
  });
}
