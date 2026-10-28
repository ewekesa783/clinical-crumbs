import 'package:isar/isar.dart';
import 'package:medvault_shared/medvault_shared.dart';

import '../../../../core/utils/uuid_generator.dart';
import '../models/citation_model.dart';
import '../models/note_model.dart';
import '../models/taxonomy_node_model.dart';

/// Creates a portable curriculum-pack backup without modifying local data.
///
/// Local database IDs, sync state, timestamps, bookmarks, history, and
/// derived taxonomy fields are intentionally excluded from the export.
class CurriculumPackExporter {
  CurriculumPackExporter({
    required Isar isar,
    String Function()? generatePackUuid,
  })  : _isar = isar,
        _generatePackUuid =
            generatePackUuid ?? UuidGenerator().call;

  final Isar _isar;
  final String Function() _generatePackUuid;

  Future<CurriculumPack> exportPack() async {
    final taxonomyModels =
        await _isar.taxonomyNodeModels.where().findAll();
    final noteModels = await _isar.noteModels.where().findAll();
    final citationModels = await _isar.citationModels.where().findAll();

    // Make output deterministic apart from the generated backup identifier.
    taxonomyModels.sort((a, b) {
      final parentComparison =
          (a.parentUuid ?? '').compareTo(b.parentUuid ?? '');
      if (parentComparison != 0) return parentComparison;

      final orderComparison = a.sortOrder.compareTo(b.sortOrder);
      if (orderComparison != 0) return orderComparison;

      return a.uuid.compareTo(b.uuid);
    });
    noteModels.sort((a, b) => a.uuid.compareTo(b.uuid));
    citationModels.sort((a, b) => a.uuid.compareTo(b.uuid));

    final pack = CurriculumPack(
      manifest: CurriculumPackManifest(
        formatVersion: currentCurriculumPackFormatVersion,
        packUuid: _generatePackUuid(),
        version: 1,
        title: 'Clinical Crumbs Full Backup',
        description:
            'Portable backup of curriculum content exported from Clinical Crumbs.',
      ),
      taxonomyNodes: taxonomyModels
          .map(
            (node) => CurriculumPackTaxonomyNode(
              uuid: node.uuid,
              parentUuid: node.parentUuid,
              nodeType: node.nodeType.name,
              title: node.title,
              slug: node.slug,
              shortDescription: node.shortDescription,
              iconKey: node.iconKey,
              sortOrder: node.sortOrder,
            ),
          )
          .toList(),
      notes: noteModels
          .map(
            (note) => CurriculumPackNote(
              uuid: note.uuid,
              topicUuid: note.topicUuid,
              mode: note.mode.name,
              title: note.title,
              bodyMarkdown: note.bodyMarkdown,
              tags: List<String>.from(note.tags),
              citationOrder: List<String>.from(note.citationOrder),
            ),
          )
          .toList(),
      citations: citationModels
          .map(
            (citation) => CurriculumPackCitation(
              uuid: citation.uuid,
              sourceType: citation.sourceType.name,
              title: citation.title,
              authors: citation.authors,
              publicationYear: citation.publicationYear,
              pageReference: citation.pageReference,
              url: citation.url,
            ),
          )
          .toList(),
    );

    final validation = const CurriculumPackValidator().validate(pack);
    if (!validation.isValid) {
      throw CurriculumPackExportException(
        'Could not create a valid backup:\n'
        '${validation.issues.join('\n')}',
      );
    }

    return pack;
  }
}

class CurriculumPackExportException implements Exception {
  const CurriculumPackExportException(this.message);

  final String message;

  @override
  String toString() => 'CurriculumPackExportException: $message';
}
