import 'package:isar/isar.dart';

import '../../../../core/database/sync_metadata_model.dart';
import '../../domain/entities/bookmark.dart';

part 'bookmark_model.g.dart';

@collection
class BookmarkModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  /// NON-unique by design (MV-IP-001 Task A.4A correction): a note may
  /// have more than one bookmark (e.g. distinct labeled bookmarks).
  @Index()
  late String noteUuid;

  String? label;

  late DateTime createdAt;

  late SyncMetadataModel sync;
}
