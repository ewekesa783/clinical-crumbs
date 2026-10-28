import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:medvault_app/core/storage/device_identity_model.dart';
import 'package:medvault_app/core/storage/learning_resource_file_storage.dart';
import 'package:medvault_app/features/library/data/models/bookmark_model.dart';
import 'package:medvault_app/features/library/data/models/citation_model.dart';
import 'package:medvault_app/features/library/data/models/history_model.dart';
import 'package:medvault_app/features/library/data/models/learning_resource_model.dart';
import 'package:medvault_app/features/library/data/models/note_model.dart';
import 'package:medvault_app/features/library/data/models/taxonomy_node_model.dart';
import 'package:medvault_app/features/library/data/repositories/full_library_backup_exporter.dart';
import 'package:medvault_app/features/library/data/repositories/full_library_backup_recovery_journal.dart';
import 'package:medvault_app/features/library/data/repositories/full_library_backup_recovery_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Isar isar;
  late Directory tempDir;
  late SharedPreferences preferences;
  late FullLibraryBackupRecoveryJournal journal;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'appearance.themePreference': 'dark',
    });
    preferences = await SharedPreferences.getInstance();

    tempDir = await Directory.systemTemp.createTemp(
      'clinical_crumbs_recovery_service_',
    );

    await Directory('${tempDir.path}/isar').create(recursive: true);

    isar = await Isar.open(
      [
        TaxonomyNodeModelSchema,
        NoteModelSchema,
        CitationModelSchema,
        BookmarkModelSchema,
        HistoryModelSchema,
        LearningResourceModelSchema,
        DeviceIdentityModelSchema,
      ],
      directory: '${tempDir.path}/isar',
    );

    await isar.writeTxn(() async {
      await isar.deviceIdentityModels.put(
        DeviceIdentityModel()..deviceId = 'preserve-this-installation',
      );
    });

    journal = FullLibraryBackupRecoveryJournal(
      documentsDirectoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    await isar.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('returns false and leaves state unchanged when no recovery is pending',
      () async {
    final service = FullLibraryBackupRecoveryService(
      isar: isar,
      preferences: preferences,
      documentsDirectoryProvider: () async => tempDir,
      journal: journal,
    );

    expect(await service.recoverIfPending(), isFalse);
    expect(await isar.deviceIdentityModels.count(), 1);
    expect(
      (await isar.deviceIdentityModels.where().findAll()).single.deviceId,
      'preserve-this-installation',
    );
    expect(preferences.getString('appearance.themePreference'), 'dark');
    expect(await journal.readPendingSnapshot(), isNull);
  });

  test('recovers a pending snapshot and clears the journal on success',
      () async {
    final backup = await FullLibraryBackupExporter(
      isar: isar,
      fileStorage: LearningResourceFileStorage(
        documentsDirectoryProvider: () async => tempDir,
      ),
      preferences: preferences,
      generatePackUuid: () => '88888888-8888-4888-8888-888888888888',
      clock: () => DateTime.utc(2026, 10, 22),
    ).exportZip();

    // Simulate a restore interrupted after the recovery snapshot was saved.
    await journal.savePendingSnapshot(backup);

    // Simulate a partial change after the snapshot was captured.
    await preferences.setString('appearance.themePreference', 'light');

    final service = FullLibraryBackupRecoveryService(
      isar: isar,
      preferences: preferences,
      documentsDirectoryProvider: () async => tempDir,
      journal: journal,
    );

    expect(await service.recoverIfPending(), isTrue);
    expect(await journal.readPendingSnapshot(), isNull);
    expect(preferences.getString('appearance.themePreference'), 'dark');
    expect(
      preferences.getBool('clinical_crumbs_full_library_snapshot_active'),
      isTrue,
    );

    // Installation identity is installation-specific, not restored data.
    expect(await isar.deviceIdentityModels.count(), 1);
    expect(
      (await isar.deviceIdentityModels.where().findAll()).single.deviceId,
      'preserve-this-installation',
    );
  });

  test('propagates recovery failure and preserves the pending snapshot',
      () async {
    final invalidSnapshot = Uint8List.fromList([1, 2, 3, 4]);
    await journal.savePendingSnapshot(invalidSnapshot);

    final service = FullLibraryBackupRecoveryService(
      isar: isar,
      preferences: preferences,
      documentsDirectoryProvider: () async => tempDir,
      journal: journal,
    );

    await expectLater(
      service.recoverIfPending(),
      throwsA(anything),
    );

    expect(
      await journal.readPendingSnapshot(),
      orderedEquals(invalidSnapshot),
    );
    expect(await isar.deviceIdentityModels.count(), 1);
    expect(
      (await isar.deviceIdentityModels.where().findAll()).single.deviceId,
      'preserve-this-installation',
    );
    expect(preferences.getString('appearance.themePreference'), 'dark');
  });
}
