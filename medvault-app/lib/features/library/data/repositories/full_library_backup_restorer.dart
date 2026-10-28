import 'dart:io';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bookmark_model.dart';
import '../models/citation_model.dart';
import '../models/history_model.dart';
import '../models/learning_resource_model.dart';
import '../models/note_model.dart';
import '../models/taxonomy_node_model.dart';
import '../../../../core/storage/learning_resource_file_storage.dart';
import 'full_library_backup_exporter.dart';
import 'full_library_backup_preparer.dart';
import 'full_library_backup_recovery_journal.dart';

/// Replaces the restorable local library with a validated full backup.
///
/// A durable pre-restore snapshot supports startup recovery if the process
/// terminates during replacement. Startup must run the recovery service before
/// any initializer or seeder can mutate the restored state.
class FullLibraryBackupRestorer {
  FullLibraryBackupRestorer({
    required Isar isar,
    SharedPreferences? preferences,
    Future<Directory> Function()? documentsDirectoryProvider,
    FullLibraryBackupPreparer preparer = const FullLibraryBackupPreparer(),
    FullLibraryBackupRecoveryJournal? recoveryJournal,
  })  : _isar = isar,
        _preferences = preferences,
        _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
        _preparer = preparer,
        _recoveryJournal = recoveryJournal ??
            FullLibraryBackupRecoveryJournal(
              documentsDirectoryProvider: documentsDirectoryProvider,
            );

  final Isar _isar;
  final SharedPreferences? _preferences;
  final Future<Directory> Function() _documentsDirectoryProvider;
  final FullLibraryBackupPreparer _preparer;
  final FullLibraryBackupRecoveryJournal _recoveryJournal;

  static const _preferenceKeys = {
    'appearance.themePreference',
    'reading.textSize',
    'pdf_reader_continuous_mode',
    'clinical_crumbs_starter_content_ledger_v1',
  };

  static bool _isRestorablePreference(String key) =>
      _preferenceKeys.contains(key) ||
      key.startsWith('pdf_reader_last_page_') ||
      key.startsWith('reader.scrollOffset.');

  /// Validates the archive before touching live data, then replaces it.
  ///
  /// Startup recovery is handled by [FullLibraryBackupRecoveryService] before
  /// any initializer or seeder runs.
  Future<void> restore(
    Uint8List zipBytes, {
    bool recoveringInterruptedRestore = false,
  }) async {
    // This is deliberately the first operation: invalid backups must not
    // mutate the database, filesystem, or preferences.
    final prepared = _preparer.prepare(zipBytes);
    final preferences = _preferences ?? await SharedPreferences.getInstance();

    if (recoveringInterruptedRestore) {
      final pending = await _recoveryJournal.readPendingSnapshot();
      if (pending == null) {
        throw StateError(
          'Recovery was requested, but no pending recovery snapshot exists.',
        );
      }
    } else {
      final pending = await _recoveryJournal.readPendingSnapshot();
      if (pending != null) {
        throw StateError(
          'An interrupted restore requires recovery before another restore.',
        );
      }

      final recoverySnapshot = await FullLibraryBackupExporter(
        isar: _isar,
        fileStorage: LearningResourceFileStorage(
          documentsDirectoryProvider: _documentsDirectoryProvider,
        ),
        preferences: preferences,
      ).exportZip();
      await _recoveryJournal.savePendingSnapshot(recoverySnapshot);
    }

    final documents = await _documentsDirectoryProvider();
    final learningResources = Directory(
      '${documents.path}/learning_resources',
    );
    final activePdfDirectory = Directory(
      '${learningResources.path}/pdfs',
    );
    final activeHtmlDirectory = Directory(
      '${learningResources.path}/html_lessons',
    );

    final operationId = '${DateTime.now().microsecondsSinceEpoch}_$pid';
    final stagingRoot = Directory(
      '${learningResources.path}/restore-staging-$operationId',
    );
    final stagingPdfDirectory = Directory(
      '${stagingRoot.path}/pdfs',
    );
    final stagingHtmlDirectory = Directory(
      '${stagingRoot.path}/html_lessons',
    );
    final rollbackRoot = Directory(
      '${learningResources.path}/restore-rollback-$operationId',
    );
    final rollbackPdfDirectory = Directory(
      '${rollbackRoot.path}/pdfs',
    );
    final rollbackHtmlDirectory = Directory(
      '${rollbackRoot.path}/html_lessons',
    );

    // Capture the previous state before making any live changes.
    final oldTaxonomy = await _isar.taxonomyNodeModels.where().findAll();
    final oldNotes = await _isar.noteModels.where().findAll();
    final oldCitations = await _isar.citationModels.where().findAll();
    final oldBookmarks = await _isar.bookmarkModels.where().findAll();
    final oldHistory = await _isar.historyModels.where().findAll();
    final oldResources = await _isar.learningResourceModels.where().findAll();

    final oldPreferenceValues = <String, Object>{};
    final previouslyPresentKeys =
        preferences.getKeys().where(_isRestorablePreference).toSet();

    for (final key in previouslyPresentKeys) {
      final value = preferences.get(key);
      if (value != null) oldPreferenceValues[key] = value;
    }

    var activePdfDirectoryMoved = false;
    var activeHtmlDirectoryMoved = false;
    var stagedPdfDirectoryActivated = false;
    var stagedHtmlDirectoryActivated = false;
    var databaseChanged = false;
    var preferencesChanged = false;

    try {
      await stagingPdfDirectory.create(recursive: true);
      await stagingHtmlDirectory.create(recursive: true);

      final resourcesByUuid = {
        for (final resource in prepared.resources) resource.uuid: resource,
      };

      // Stage and verify every resource before replacing either active folder.
      for (final entry in prepared.resourceBytesByUuid.entries) {
        final resource = resourcesByUuid[entry.key];
        if (resource == null) {
          throw StateError(
            'No metadata exists for restored resource "${entry.key}".',
          );
        }

        final segments = resource.relativeFilePath.split('/');
        if (segments.length != 3 ||
            segments[0] != 'learning_resources' ||
            (segments[1] != 'pdfs' &&
                segments[1] != 'html_lessons')) {
          throw StateError(
            'Unsupported restored resource path: '
            '"${resource.relativeFilePath}".',
          );
        }

        final isHtmlLesson = segments[1] == 'html_lessons';
        final stagingDirectory =
            isHtmlLesson ? stagingHtmlDirectory : stagingPdfDirectory;
        final expectedName = isHtmlLesson
            ? '${resource.uuid}.zip'
            : '${resource.uuid}.pdf';

        if (segments[2] != expectedName) {
          throw StateError(
            'Unexpected restored resource filename: "${segments[2]}".',
          );
        }

        final bytes = entry.value;
        final file = File('${stagingDirectory.path}/$expectedName');
        await file.writeAsBytes(bytes, flush: true);

        final writtenBytes = await file.readAsBytes();
        if (writtenBytes.length != bytes.length) {
          throw FileSystemException(
            'Staged resource size verification failed.',
            file.path,
          );
        }
        for (var i = 0; i < bytes.length; i++) {
          if (writtenBytes[i] != bytes[i]) {
            throw FileSystemException(
              'Staged resource content verification failed.',
              file.path,
            );
          }
        }
      }

      await rollbackRoot.create(recursive: true);

      // Preserve both old resource folders before activating the new snapshot.
      if (await activePdfDirectory.exists()) {
        await activePdfDirectory.rename(rollbackPdfDirectory.path);
        activePdfDirectoryMoved = true;
      }
      if (await activeHtmlDirectory.exists()) {
        await activeHtmlDirectory.rename(rollbackHtmlDirectory.path);
        activeHtmlDirectoryMoved = true;
      }

      // Activate each complete staged folder. Track separately so a failure
      // between the two renames can safely roll back whichever already moved.
      await stagingPdfDirectory.rename(activePdfDirectory.path);
      stagedPdfDirectoryActivated = true;

      await stagingHtmlDirectory.rename(activeHtmlDirectory.path);
      stagedHtmlDirectoryActivated = true;

      await _isar.writeTxn(() async {
        await _isar.taxonomyNodeModels.clear();
        await _isar.noteModels.clear();
        await _isar.citationModels.clear();
        await _isar.bookmarkModels.clear();
        await _isar.historyModels.clear();
        await _isar.learningResourceModels.clear();

        await _isar.taxonomyNodeModels.putAll(prepared.taxonomy);
        await _isar.noteModels.putAll(prepared.notes);
        await _isar.citationModels.putAll(prepared.citations);
        await _isar.bookmarkModels.putAll(prepared.bookmarks);
        await _isar.historyModels.putAll(prepared.history);
        await _isar.learningResourceModels.putAll(prepared.resources);
      });
      databaseChanged = true;

      // Mark preferences as potentially changed before the first mutation,
      // so a failure halfway through still triggers preference rollback.
      preferencesChanged = true;

      // Replace only the preference keys this backup format owns.
      for (final key in preferences.getKeys().where(_isRestorablePreference)) {
        await preferences.remove(key);
      }
      for (final entry in prepared.preferenceValues.entries) {
        await _setPreference(preferences, entry.key, entry.value);
      }

      // Confirm every restored resource exists at its managed path.
      for (final resource in prepared.resources) {
        final file = File(
          '${documents.path}/${resource.relativeFilePath}',
        );
        if (!await file.exists() ||
            await file.length() != resource.fileSizeBytes) {
          throw FileSystemException(
            'Restored resource verification failed.',
            file.path,
          );
        }
      }
    } catch (error, stackTrace) {
      Object? rollbackError;

      // Restore preferences to their exact previous presence/value state.
      try {
        if (preferencesChanged) {
          for (final key
              in preferences.getKeys().where(_isRestorablePreference)) {
            await preferences.remove(key);
          }
          for (final key in previouslyPresentKeys) {
            final value = oldPreferenceValues[key];
            if (value != null) await _setPreference(preferences, key, value);
          }
        }
      } catch (e) {
        rollbackError ??= e;
      }

      // Restore the old database snapshot transactionally if the replacement
      // transaction had already committed.
      try {
        if (databaseChanged) {
          await _isar.writeTxn(() async {
            await _isar.taxonomyNodeModels.clear();
            await _isar.noteModels.clear();
            await _isar.citationModels.clear();
            await _isar.bookmarkModels.clear();
            await _isar.historyModels.clear();
            await _isar.learningResourceModels.clear();

            await _isar.taxonomyNodeModels.putAll(oldTaxonomy);
            await _isar.noteModels.putAll(oldNotes);
            await _isar.citationModels.putAll(oldCitations);
            await _isar.bookmarkModels.putAll(oldBookmarks);
            await _isar.historyModels.putAll(oldHistory);
            await _isar.learningResourceModels.putAll(oldResources);
          });
        }
      } catch (e) {
        rollbackError ??= e;
      }

      // Roll back each resource directory independently. Never overwrite
      // an old directory; first move any newly activated directory aside.
      try {
        if (stagedPdfDirectoryActivated &&
            await activePdfDirectory.exists()) {
          final failedDirectory = Directory(
            '${learningResources.path}/restore-failed-$operationId/pdfs',
          );
          await failedDirectory.parent.create(recursive: true);
          await activePdfDirectory.rename(failedDirectory.path);
        }
      } catch (e) {
        rollbackError ??= e;
      }

      try {
        if (stagedHtmlDirectoryActivated &&
            await activeHtmlDirectory.exists()) {
          final failedDirectory = Directory(
            '${learningResources.path}/restore-failed-$operationId/html_lessons',
          );
          await failedDirectory.parent.create(recursive: true);
          await activeHtmlDirectory.rename(failedDirectory.path);
        }
      } catch (e) {
        rollbackError ??= e;
      }

      try {
        if (activePdfDirectoryMoved &&
            await rollbackPdfDirectory.exists()) {
          await rollbackPdfDirectory.rename(activePdfDirectory.path);
        }
      } catch (e) {
        rollbackError ??= e;
      }

      try {
        if (activeHtmlDirectoryMoved &&
            await rollbackHtmlDirectory.exists()) {
          await rollbackHtmlDirectory.rename(activeHtmlDirectory.path);
        }
      } catch (e) {
        rollbackError ??= e;
      }

      if (rollbackError == null && !recoveringInterruptedRestore) {
        await _recoveryJournal.clear();
      }

      if (rollbackError != null) {
        Error.throwWithStackTrace(
          StateError(
            'Restore failed: $error. Rollback also failed: $rollbackError. '
            'Preserve the restore directories for recovery.',
          ),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      // Delete only temporary staging data. Retain rollback files if a
      // rollback failure may have left recovery work for the operator.
      try {
        if (await stagingRoot.exists()) {
          await stagingRoot.delete(recursive: true);
        }
      } catch (_) {
        // Cleanup failure must not mask the restore result.
      }
    }

    // Record that a complete library snapshot is active before clearing the
    // recovery journal. If the process stops here, startup recovery remains
    // available; if it stops after the journal is cleared, startup still
    // knows not to reseed or modify the restored snapshot.
    final markerSaved = await preferences.setBool(
      'clinical_crumbs_full_library_snapshot_active',
      true,
    );
    if (!markerSaved) {
      throw StateError(
        'Could not persist the restored-library snapshot marker. '
        'The recovery snapshot has been retained for startup recovery.',
      );
    }

    // Clear the durable recovery marker only after all active-state writes,
    // verification, and the snapshot-preservation marker have succeeded.
    await _recoveryJournal.clear();

    // The previous resource snapshot is no longer needed after successful
    // verification. Cleanup is deliberately after all active-state writes.
    if (await rollbackRoot.exists()) {
      await rollbackRoot.delete(recursive: true);
    }
  }

  static Future<void> _setPreference(
    SharedPreferences preferences,
    String key,
    Object value,
  ) async {
    if (value is String) {
      await preferences.setString(key, value);
    } else if (value is bool) {
      await preferences.setBool(key, value);
    } else if (value is int) {
      await preferences.setInt(key, value);
    } else if (value is double) {
      await preferences.setDouble(key, value);
    } else {
      throw ArgumentError.value(
        value,
        'value',
        'Unsupported preference type.',
      );
    }
  }
}
