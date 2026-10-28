import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/library/data/bootstrap/starter_content_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;
  late StarterContentLedger ledger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    ledger = StarterContentLedger(preferences);
  });

  test('registers bundled resource UUIDs', () async {
    await ledger.registerBundledResources(['starter-a', 'starter-b']);

    expect(ledger.knownResourceUuids, {'starter-a', 'starter-b'});
    expect(ledger.deletedResourceUuids, isEmpty);
  });

  test('records deletion of a known starter resource', () async {
    await ledger.registerBundledResources(['starter-a', 'starter-b']);

    expect(await ledger.recordDeletionIfStarter('starter-a'), isTrue);
    expect(ledger.deletedResourceUuids, {'starter-a'});
    expect(ledger.knownResourceUuids, {'starter-a', 'starter-b'});
  });

  test('does not record deletion of an unknown resource', () async {
    await ledger.registerBundledResources(['starter-a']);

    expect(await ledger.recordDeletionIfStarter('user-imported-pdf'), isFalse);
    expect(ledger.deletedResourceUuids, isEmpty);
  });

  test('preserves deletions when later starter resources are registered',
      () async {
    await ledger.registerBundledResources(['starter-a']);
    await ledger.recordDeletionIfStarter('starter-a');

    await ledger.registerBundledResources(['starter-a', 'starter-b']);

    expect(ledger.knownResourceUuids, {'starter-a', 'starter-b'});
    expect(ledger.deletedResourceUuids, {'starter-a'});
  });

  test('records and persists installed content version', () async {
    await ledger.recordInstalledContentVersion(3);

    expect(ledger.installedContentVersion, 3);
    expect(StarterContentLedger(preferences).installedContentVersion, 3);
  });

  test('preserves installed version when resources and deletions change',
      () async {
    await ledger.recordInstalledContentVersion(4);
    await ledger.registerBundledResources(['starter-a', 'starter-b']);
    await ledger.recordDeletionIfStarter('starter-a');

    expect(ledger.installedContentVersion, 4);
    expect(ledger.deletedResourceUuids, {'starter-a'});
  });

  test('reads legacy ledger without an installed version', () async {
    SharedPreferences.setMockInitialValues({
      StarterContentLedger.storageKey:
          '{"knownResourceUuids":["starter-a"],'
          '"deletedResourceUuids":["starter-a"]}',
    });
    preferences = await SharedPreferences.getInstance();
    ledger = StarterContentLedger(preferences);

    expect(ledger.knownResourceUuids, {'starter-a'});
    expect(ledger.deletedResourceUuids, {'starter-a'});
    expect(ledger.installedContentVersion, isNull);

    await ledger.registerBundledResources(['starter-b']);
    expect(ledger.installedContentVersion, isNull);
    expect(ledger.deletedResourceUuids, {'starter-a'});
  });

  test('persists ledger across instances', () async {
    await ledger.registerBundledResources(['starter-a']);
    await ledger.recordDeletionIfStarter('starter-a');

    final reopenedLedger = StarterContentLedger(preferences);

    expect(reopenedLedger.knownResourceUuids, {'starter-a'});
    expect(reopenedLedger.deletedResourceUuids, {'starter-a'});
  });
}
