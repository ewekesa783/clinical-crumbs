import 'package:isar/isar.dart';

part 'sync_metadata_model.g.dart';

/// Isar-embedded persistence model mirroring [SyncMetadata].
///
/// Embedded Isar objects cannot carry `@Index()` annotations — indexing
/// embedded fields is not supported by Isar — so none are present here,
/// in contrast to top-level collection models.
@embedded
class SyncMetadataModel {
  String? remoteId;

  late DateTime lastModifiedLocal;

  DateTime? lastSyncedAt;

  late bool isDirty;

  late bool isDeleted;

  late String deviceId;

  late int syncRevision;
}
