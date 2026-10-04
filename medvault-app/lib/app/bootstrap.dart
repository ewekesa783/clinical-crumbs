import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

/// Opens the application's single Isar database instance.
///
/// KNOWN GAP (preserved intentionally — do not "fix" without an explicit
/// task authorizing it): the schema list passed to [Isar.open] is empty.
/// None of the five Phase 1 collections (TaxonomyNodeModel, NoteModel,
/// CitationModel, BookmarkModel, HistoryModel) are registered here yet.
/// Registering them is deferred to the task that wires up the composition
/// root, which has not been authorized as of the current project state
/// (MV-IP-002 Task Group A is complete; there is no Task Group B).
Future<Isar> bootstrap() async {
  final directory = await getApplicationDocumentsDirectory();
  return Isar.open(
    [], // TODO(known-gap): register TaxonomyNodeModel, NoteModel,
    //     CitationModel, BookmarkModel, HistoryModel schemas here.
    directory: directory.path,
  );
}
