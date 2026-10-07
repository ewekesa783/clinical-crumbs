import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:medvault_app/features/library/data/models/bookmark_model.dart';
import 'package:medvault_app/features/library/data/models/citation_model.dart';
import 'package:medvault_app/features/library/data/models/history_model.dart';
import 'package:medvault_app/features/library/data/models/note_model.dart';
import 'package:medvault_app/features/library/data/models/taxonomy_node_model.dart';
import 'package:medvault_app/core/storage/device_identity_model.dart';

/// Opens the application's single Isar database instance.
///
/// All persistent MedVault collections are registered here so that the
/// application uses one shared Isar database for its local data layer.
Future<Isar> bootstrap() async {
  final directory = await getApplicationDocumentsDirectory();

  return Isar.open(
    [
      TaxonomyNodeModelSchema,
      NoteModelSchema,
      CitationModelSchema,
      BookmarkModelSchema,
      HistoryModelSchema,
      DeviceIdentityModelSchema,
    ],
    directory: directory.path,
  );
}
