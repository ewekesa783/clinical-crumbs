import "package:isar/isar.dart";
import "package:medvault_shared/medvault_shared.dart";

import "../../../../core/sync/sync_metadata.dart";
import "../../domain/entities/citation.dart";
import "../../domain/entities/note.dart";
import "../../domain/entities/taxonomy_node.dart";
import "../models/citation_mapper.dart";
import "../models/citation_model.dart";
import "../models/note_mapper.dart";
import "../models/note_model.dart";
import "../models/taxonomy_node_mapper.dart";
import "../models/taxonomy_node_model.dart";

/// Validates and imports a curriculum pack without overwriting existing data.
class CurriculumPackImporter {
  CurriculumPackImporter({
    required Isar isar,
    required SyncMetadata Function() createSyncMetadata,
    required DateTime Function() now,
  })  : _isar = isar,
        _createSyncMetadata = createSyncMetadata,
        _now = now;

  final Isar _isar;
  final SyncMetadata Function() _createSyncMetadata;
  final DateTime Function() _now;

  Future<CurriculumPackImportResult> importPack(CurriculumPack pack) async {
    final validation = const CurriculumPackValidator().validate(pack);
    if (!validation.isValid) {
      throw CurriculumPackImportException(
        "Pack validation failed:\n${validation.issues.join("\n")}",
      );
    }

    return _isar.writeTxn(() async {
      final existingTaxonomy = await _isar.taxonomyNodeModels.where().findAll();
      final existingNotes = await _isar.noteModels.where().findAll();
      final existingCitations = await _isar.citationModels.where().findAll();

      _checkConflicts(
        pack,
        existingTaxonomy,
        existingNotes,
        existingCitations,
      );

      final timestamp = _now();
      final nodesByUuid = {
        for (final node in pack.taxonomyNodes) node.uuid: node,
      };
      final pathByUuid = <String, String>{};
      final depthByUuid = <String, int>{};

      String pathFor(String uuid) {
        final cached = pathByUuid[uuid];
        if (cached != null) return cached;

        final node = nodesByUuid[uuid]!;
        final parentUuid = node.parentUuid;
        final path = parentUuid == null
            ? node.uuid
            : "${pathFor(parentUuid)}/${node.uuid}";

        pathByUuid[uuid] = path;
        depthByUuid[uuid] =
            parentUuid == null ? 0 : depthByUuid[parentUuid]! + 1;
        return path;
      }

      final noteCounts = <String, int>{};
      for (final note in pack.notes) {
        noteCounts.update(
          note.topicUuid,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      final taxonomyModels = <TaxonomyNodeModel>[];
      for (final node in pack.taxonomyNodes) {
        pathFor(node.uuid);
        taxonomyModels.add(TaxonomyNodeMapper.toModel(TaxonomyNode(
          uuid: node.uuid,
          parentUuid: node.parentUuid,
          path: pathByUuid[node.uuid]!,
          depth: depthByUuid[node.uuid]!,
          nodeType: NodeType.values.byName(node.nodeType),
          title: node.title,
          slug: node.slug,
          shortDescription: node.shortDescription,
          iconKey: node.iconKey,
          sortOrder: node.sortOrder,
          noteCount: noteCounts[node.uuid] ?? 0,
          curriculumPackUuid: pack.manifest.packUuid,
          curriculumPackVersion: pack.manifest.version,
          isUserCreated: false,
          createdAt: timestamp,
          updatedAt: timestamp,
          sync: _createSyncMetadata(),
        )));
      }

      final citationModels = pack.citations.map((citation) {
        return CitationMapper.toModel(Citation(
          uuid: citation.uuid,
          sourceType: SourceType.values.byName(citation.sourceType),
          title: citation.title,
          authors: citation.authors,
          publicationYear: citation.publicationYear,
          pageReference: citation.pageReference,
          url: citation.url,
          createdAt: timestamp,
          updatedAt: timestamp,
          sync: _createSyncMetadata(),
        ));
      }).toList();

      final noteModels = pack.notes.map((note) {
        return NoteMapper.toModel(Note(
          uuid: note.uuid,
          topicUuid: note.topicUuid,
          mode: Mode.values.byName(note.mode),
          title: note.title,
          bodyMarkdown: note.bodyMarkdown,
          plainTextExtract: null,
          tags: List<String>.from(note.tags),
          citationOrder: List<String>.from(note.citationOrder),
          isPinned: false,
          createdAt: timestamp,
          updatedAt: timestamp,
          sync: _createSyncMetadata(),
        ));
      }).toList();

      await _isar.taxonomyNodeModels.putAll(taxonomyModels);
      await _isar.citationModels.putAll(citationModels);
      await _isar.noteModels.putAll(noteModels);

      return CurriculumPackImportResult(
        taxonomyNodesImported: taxonomyModels.length,
        citationsImported: citationModels.length,
        notesImported: noteModels.length,
      );
    });
  }

  void _checkConflicts(
    CurriculumPack pack,
    List<TaxonomyNodeModel> existingTaxonomy,
    List<NoteModel> existingNotes,
    List<CitationModel> existingCitations,
  ) {
    final taxonomyUuids = existingTaxonomy.map((n) => n.uuid).toSet();
    final noteUuids = existingNotes.map((n) => n.uuid).toSet();
    final citationUuids = existingCitations.map((n) => n.uuid).toSet();

    for (final node in pack.taxonomyNodes) {
      if (taxonomyUuids.contains(node.uuid)) {
        throw CurriculumPackImportException(
          "Taxonomy UUID \"${node.uuid}\" already exists.",
        );
      }
    }

    final siblingSlugs = <String>{
      for (final node in existingTaxonomy)
        "${node.parentUuid ?? ""}\u0000${node.slug}",
    };
    for (final node in pack.taxonomyNodes) {
      final key = "${node.parentUuid ?? ""}\u0000${node.slug}";
      if (!siblingSlugs.add(key)) {
        throw CurriculumPackImportException(
          "Taxonomy slug \"${node.slug}\" already exists under the same parent.",
        );
      }
    }

    final noteCombinations = <String>{
      for (final note in existingNotes)
        "${note.topicUuid}\u0000${note.mode.name}",
    };
    for (final note in pack.notes) {
      if (noteUuids.contains(note.uuid)) {
        throw CurriculumPackImportException(
          "Note UUID \"${note.uuid}\" already exists.",
        );
      }
      final key = "${note.topicUuid}\u0000${note.mode}";
      if (!noteCombinations.add(key)) {
        throw CurriculumPackImportException(
          "A note already exists for topic \"${note.topicUuid}\" and mode \"${note.mode}\".",
        );
      }
    }

    for (final citation in pack.citations) {
      if (citationUuids.contains(citation.uuid)) {
        throw CurriculumPackImportException(
          "Citation UUID \"${citation.uuid}\" already exists.",
        );
      }
    }
  }
}

class CurriculumPackImportResult {
  const CurriculumPackImportResult({
    required this.taxonomyNodesImported,
    required this.citationsImported,
    required this.notesImported,
  });

  final int taxonomyNodesImported;
  final int citationsImported;
  final int notesImported;
}

class CurriculumPackImportException implements Exception {
  const CurriculumPackImportException(this.message);

  final String message;

  @override
  String toString() => "CurriculumPackImportException: $message";
}
