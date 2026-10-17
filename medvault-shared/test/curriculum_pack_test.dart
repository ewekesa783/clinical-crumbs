import 'dart:convert';

import 'package:medvault_shared/medvault_shared.dart';
import 'package:test/test.dart';

void main() {
  group('CurriculumPack JSON contract', () {
    test('round-trips manifest, taxonomy, notes, and citations', () {
      const pack = CurriculumPack(
        manifest: CurriculumPackManifest(
          formatVersion: currentCurriculumPackFormatVersion,
          packUuid: 'pack-test-001',
          version: 1,
          title: 'Synthetic Test Pack',
          description: 'Non-clinical test data',
        ),
        taxonomyNodes: [
          CurriculumPackTaxonomyNode(
            uuid: 'node-test-001',
            nodeType: 'subject',
            title: 'Synthetic Subject',
            slug: 'synthetic-subject',
            sortOrder: 0,
          ),
        ],
        notes: [
          CurriculumPackNote(
            uuid: 'note-test-001',
            topicUuid: 'node-test-001',
            mode: 'detailedNotes',
            title: 'Example Note',
            bodyMarkdown: '# Example\n\nNon-clinical placeholder text.',
            tags: ['synthetic', 'test'],
            citationOrder: ['citation-test-001'],
          ),
        ],
        citations: [
          CurriculumPackCitation(
            uuid: 'citation-test-001',
            sourceType: 'other',
            title: 'Synthetic Reference',
            authors: 'Test Author',
            publicationYear: 2025,
            pageReference: 'p. 1',
            url: 'https://example.com/reference',
          ),
        ],
      );

      final encoded = jsonEncode(pack.toJson());
      final decodedJson =
          Map<String, dynamic>.from(jsonDecode(encoded) as Map);
      final restored = CurriculumPack.fromJson(decodedJson);

      expect(restored.manifest.packUuid, pack.manifest.packUuid);
      expect(restored.manifest.formatVersion, pack.manifest.formatVersion);
      expect(restored.manifest.version, pack.manifest.version);
      expect(restored.manifest.title, pack.manifest.title);

      expect(restored.taxonomyNodes, hasLength(1));
      expect(restored.taxonomyNodes.single.uuid, 'node-test-001');
      expect(restored.taxonomyNodes.single.parentUuid, isNull);
      expect(restored.taxonomyNodes.single.nodeType, 'subject');

      expect(restored.notes, hasLength(1));
      expect(restored.notes.single.bodyMarkdown, pack.notes.single.bodyMarkdown);
      expect(restored.notes.single.tags, ['synthetic', 'test']);
      expect(restored.notes.single.citationOrder, ['citation-test-001']);

      expect(restored.citations, hasLength(1));
      expect(restored.citations.single.authors, 'Test Author');
      expect(restored.citations.single.publicationYear, 2025);
      expect(restored.citations.single.url, 'https://example.com/reference');
    });

    test('omits optional fields when they are absent', () {
      const manifest = CurriculumPackManifest(
        formatVersion: 1,
        packUuid: 'pack-minimal',
        version: 1,
        title: 'Minimal Test Pack',
      );

      expect(manifest.toJson().containsKey('description'), isFalse);
    });
  });
}
