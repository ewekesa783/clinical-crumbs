import 'package:isar/isar.dart';

import '../../../../core/database/sync_metadata_model.dart';
import '../../domain/entities/citation.dart';

part 'citation_model.g.dart';

@collection
class CitationModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @enumerated
  late SourceType sourceType;

  late String title;

  String? authors;

  int? publicationYear;

  String? pageReference;

  String? url;

  late DateTime createdAt;

  late DateTime updatedAt;

  late SyncMetadataModel sync;
}
