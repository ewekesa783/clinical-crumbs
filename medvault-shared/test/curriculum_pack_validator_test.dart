import 'package:medvault_shared/medvault_shared.dart';
import 'package:test/test.dart';

void main() {
  const validator = CurriculumPackValidator();

  group('CurriculumPackValidator', () {
    test('accepts a structurally valid synthetic pack', () {
      const pack = CurriculumPack(
        manifest: CurriculumPackManifest(
          formatVersion: currentCurriculumPackFormatVersion,
          packUuid: 'pack-001',
          version: 1,
          title: 'Synthetic Test Pack',
        ),
        taxonomyNodes: [
          CurriculumPackTaxonomyNode(
            uuid: 'subject-001',
            nodeType: 'subject',
            title: 'Synthetic Subject',
            slug: 'synthetic-subject',
            sortOrder: 0,
          ),
          CurriculumPackTaxonomyNode(
            uuid: 'topic-001',
            parentUuid: 'subject-001',
            nodeType: 'topic',
            title: 'Synthetic Topic',
            slug: 'synthetic-topic',
            sortOrder: 0,
          ),
        ],
        notes: [
          CurriculumPackNote(
            uuid: 'note-001',
            topicUuid: 'topic-001',
            mode: 'detailedNotes',
            title: 'Example Note',
            bodyMarkdown: 'Synthetic placeholder text.',
            tags: ['example'],
            citationOrder: ['citation-001'],
          ),
        ],
        citations: [
          CurriculumPackCitation(
            uuid: 'citation-001',
            sourceType: 'other',
            title: 'Synthetic Reference',
          ),
        ],
      );

      final result = validator.validate(pack);

      expect(result.isValid, isTrue, reason: result.issues.join('\n'));
      expect(result.issues, isEmpty);
    });

    test('reports unsupported versions, duplicate IDs, and broken references', () {
      const pack = CurriculumPack(
        manifest: CurriculumPackManifest(
          formatVersion: 999,
          packUuid: 'pack-001',
          version: 0,
          title: 'Malformed Test Pack',
        ),
        taxonomyNodes: [
          CurriculumPackTaxonomyNode(
            uuid: 'node-001',
            nodeType: 'unknown',
            title: 'First Node',
            slug: 'first-node',
            sortOrder: 0,
          ),
          CurriculumPackTaxonomyNode(
            uuid: 'node-001',
            parentUuid: 'missing-parent',
            nodeType: 'topic',
            title: 'Duplicate Node',
            slug: 'duplicate-node',
            sortOrder: 0,
          ),
        ],
        notes: [
          CurriculumPackNote(
            uuid: 'note-001',
            topicUuid: 'missing-topic',
            mode: 'unknown',
            title: 'Malformed Note',
            bodyMarkdown: 'Synthetic placeholder text.',
            tags: [''],
            citationOrder: ['missing-citation'],
          ),
          CurriculumPackNote(
            uuid: 'note-001',
            topicUuid: 'node-001',
            mode: 'detailedNotes',
            title: 'Duplicate Note',
            bodyMarkdown: 'Synthetic placeholder text.',
            tags: [],
            citationOrder: [],
          ),
        ],
        citations: [
          CurriculumPackCitation(
            uuid: 'citation-001',
            sourceType: 'unknown',
            title: '',
          ),
          CurriculumPackCitation(
            uuid: 'citation-001',
            sourceType: 'other',
            title: 'Duplicate Citation',
          ),
        ],
      );

      final result = validator.validate(pack);
      final messages = result.issues.map((issue) => issue.message).join('\n');

      expect(result.isValid, isFalse);
      expect(messages, contains('Unsupported format version'));
      expect(messages, contains('Pack version must be at least 1'));
      expect(messages, contains('Duplicate taxonomy UUID'));
      expect(messages, contains('Unknown node type'));
      expect(messages, contains('does not exist in this pack'));
      expect(messages, contains('Unknown note mode'));
      expect(messages, contains('Duplicate note UUID'));
      expect(messages, contains('Duplicate citation UUID'));
      expect(messages, contains('Unknown citation source type'));
      expect(messages, contains('Citation title must not be empty'));
    });

    test('detects taxonomy cycles', () {
      const pack = CurriculumPack(
        manifest: CurriculumPackManifest(
          formatVersion: currentCurriculumPackFormatVersion,
          packUuid: 'pack-cycle',
          version: 1,
          title: 'Cycle Test Pack',
        ),
        taxonomyNodes: [
          CurriculumPackTaxonomyNode(
            uuid: 'node-a',
            parentUuid: 'node-b',
            nodeType: 'topic',
            title: 'Node A',
            slug: 'node-a',
            sortOrder: 0,
          ),
          CurriculumPackTaxonomyNode(
            uuid: 'node-b',
            parentUuid: 'node-a',
            nodeType: 'topic',
            title: 'Node B',
            slug: 'node-b',
            sortOrder: 0,
          ),
        ],
        notes: [],
        citations: [],
      );

      final result = validator.validate(pack);

      expect(result.isValid, isFalse);
      expect(
        result.issues.any((issue) => issue.message.contains('cycle')),
        isTrue,
      );
    });
  });
}
