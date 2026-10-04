import 'package:isar/isar.dart';

import '../../../../core/database/sync_metadata_model.dart';
import '../../domain/entities/note.dart';

part 'note_model.g.dart';

/// Isar persistence model for [Note].
///
/// `topicUuid` + `mode` form a composite unique index: a topic may have
/// at most one note per mode.
@collection
class NoteModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index(composite: [CompositeIndex('mode')], unique: true)
  late String topicUuid;

  @enumerated
  late Mode mode;

  late String title;

  late String bodyMarkdown;

  String? plainTextExtract;

  late List<String> tags;

  late List<String> citationOrder;

  late bool isPinned;

  late DateTime createdAt;

  late DateTime updatedAt;

  late SyncMetadataModel sync;
}
