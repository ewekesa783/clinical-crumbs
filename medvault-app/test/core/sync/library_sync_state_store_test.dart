import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/core/sync/library_sync_state.dart';
import 'package:medvault_app/core/sync/library_sync_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibrarySyncStateStore', () {
    test('loads an empty state when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final state = LibrarySyncStateStore(
        preferences: preferences,
      ).load();

      expect(state.installedReleaseId, isNull);
      expect(state.latestAvailableReleaseId, isNull);
      expect(state.lastSuccessfulCheckAt, isNull);
      expect(state.lastSuccessfulUpdateAt, isNull);
    });

    test('persists and reloads release identifiers and UTC timestamps',
        () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = LibrarySyncStateStore(preferences: preferences);
      final checkedAt = DateTime.utc(2026, 10, 22, 9, 30);
      final updatedAt = DateTime.utc(2026, 10, 21, 15, 45);

      await store.save(
        LibrarySyncState(
          installedReleaseId: 'release-1',
          latestAvailableReleaseId: 'release-2',
          lastSuccessfulCheckAt: checkedAt,
          lastSuccessfulUpdateAt: updatedAt,
        ),
      );

      final loaded = store.load();
      expect(loaded.installedReleaseId, 'release-1');
      expect(loaded.latestAvailableReleaseId, 'release-2');
      expect(loaded.lastSuccessfulCheckAt, checkedAt);
      expect(loaded.lastSuccessfulUpdateAt, updatedAt);
      expect(
        preferences.getString('library_sync.last_successful_check_at'),
        checkedAt.toIso8601String(),
      );
    });

    test('clears values when saved state fields are null', () async {
      SharedPreferences.setMockInitialValues({
        'library_sync.installed_release_id': 'release-1',
        'library_sync.latest_available_release_id': 'release-2',
        'library_sync.last_successful_check_at':
            '2026-10-22T09:30:00.000Z',
        'library_sync.last_successful_update_at':
            '2026-10-21T15:45:00.000Z',
      });
      final preferences = await SharedPreferences.getInstance();
      final store = LibrarySyncStateStore(preferences: preferences);

      await store.save(const LibrarySyncState());

      expect(store.load().installedReleaseId, isNull);
      expect(store.load().latestAvailableReleaseId, isNull);
      expect(store.load().lastSuccessfulCheckAt, isNull);
      expect(store.load().lastSuccessfulUpdateAt, isNull);
    });

    test('ignores malformed stored timestamps', () async {
      SharedPreferences.setMockInitialValues({
        'library_sync.last_successful_check_at': 'not-a-date',
      });
      final preferences = await SharedPreferences.getInstance();

      final state = LibrarySyncStateStore(
        preferences: preferences,
      ).load();

      expect(state.lastSuccessfulCheckAt, isNull);
    });
  });
}
