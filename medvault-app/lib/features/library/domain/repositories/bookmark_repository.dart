import '../entities/bookmark.dart';

abstract class BookmarkRepository {
  Future<void> save(Bookmark bookmark);

  /// Removes every bookmark associated with [noteUuid].
  Future<void> deleteByNoteUuid(String noteUuid);

  /// Removes every bookmark without deleting the underlying resources.
  Future<void> deleteAll();

  Future<Bookmark?> getByUuid(String uuid);

  /// A note may have more than one bookmark; this returns all of them.
  Future<List<Bookmark>> getByNoteUuid(String noteUuid);

  /// Returns the newest bookmarks first, up to [limit] entries.
  Future<List<Bookmark>> getRecent({int limit = 10});
}
