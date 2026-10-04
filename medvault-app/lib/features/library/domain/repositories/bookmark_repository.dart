import '../entities/bookmark.dart';

abstract class BookmarkRepository {
  Future<void> save(Bookmark bookmark);

  Future<Bookmark?> getByUuid(String uuid);

  /// A note may have more than one bookmark; this returns all of them.
  Future<List<Bookmark>> getByNoteUuid(String noteUuid);
}
