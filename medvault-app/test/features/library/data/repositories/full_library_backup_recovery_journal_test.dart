import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:medvault_app/features/library/data/repositories/full_library_backup_recovery_journal.dart';

void main() {
  late Directory tempDir;
  late FullLibraryBackupRecoveryJournal journal;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'clinical_crumbs_recovery_journal_',
    );
    journal = FullLibraryBackupRecoveryJournal(
      documentsDirectoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('returns null when no recovery is pending', () async {
    expect(await journal.readPendingSnapshot(), isNull);
  });

  test('pending snapshot survives a new journal instance and can be cleared',
      () async {
    final bytes = Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 55]);

    await journal.savePendingSnapshot(bytes);

    final nextLaunchJournal = FullLibraryBackupRecoveryJournal(
      documentsDirectoryProvider: () async => tempDir,
    );
    expect(
      await nextLaunchJournal.readPendingSnapshot(),
      orderedEquals(bytes),
    );

    await nextLaunchJournal.clear();
    expect(await journal.readPendingSnapshot(), isNull);
  });

  test('refuses to overwrite an existing pending recovery snapshot', () async {
    await journal.savePendingSnapshot(Uint8List.fromList([1, 2, 3]));

    await expectLater(
      journal.savePendingSnapshot(Uint8List.fromList([4, 5, 6])),
      throwsA(isA<StateError>()),
    );

    expect(
      await journal.readPendingSnapshot(),
      orderedEquals([1, 2, 3]),
    );
  });

  test('fails closed when pending marker exists but snapshot is missing',
      () async {
    final recoveryDir = Directory(
      '${tempDir.path}/clinical_crumbs_restore_recovery',
    );
    await recoveryDir.create(recursive: true);
    await File('${recoveryDir.path}/restore_pending').writeAsString('pending');

    await expectLater(
      journal.readPendingSnapshot(),
      throwsA(isA<StateError>()),
    );
  });
}
