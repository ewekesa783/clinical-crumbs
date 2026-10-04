import 'package:isar/isar.dart';

import '../../../../core/database/sync_metadata_model.dart';
import '../../domain/entities/history.dart';

part 'history_model.g.dart';

@collection
class HistoryModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  /// UNIQUE by design (MV-IP-001 Task A.5A correction): at most one
  /// history entry exists per note. Contrast with BookmarkModel.noteUuid,
  /// which is intentionally non-unique.
  @Index(unique: true)
  late String noteUuid;

  late DateTime viewedAt;

  late SyncMetadataModel sync;
}
