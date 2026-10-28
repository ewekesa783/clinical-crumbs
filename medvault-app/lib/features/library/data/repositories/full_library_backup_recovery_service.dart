import 'dart:io';

import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_library_backup_recovery_journal.dart';
import 'full_library_backup_restorer.dart';

/// Recovers an interrupted full-library restore before startup initialization.
class FullLibraryBackupRecoveryService {
  FullLibraryBackupRecoveryService({
    required Isar isar,
    required SharedPreferences preferences,
    Future<Directory> Function()? documentsDirectoryProvider,
    FullLibraryBackupRecoveryJournal? journal,
  })  : _isar = isar,
        _preferences = preferences,
        _documentsDirectoryProvider = documentsDirectoryProvider,
        _journal = journal ??
            FullLibraryBackupRecoveryJournal(
              documentsDirectoryProvider: documentsDirectoryProvider,
            );

  final Isar _isar;
  final SharedPreferences _preferences;
  final Future<Directory> Function()? _documentsDirectoryProvider;
  final FullLibraryBackupRecoveryJournal _journal;

  /// Returns true when a pending restore was recovered successfully.
  ///
  /// If recovery fails, the error propagates so startup cannot continue
  /// against a potentially incomplete library.
  Future<bool> recoverIfPending() async {
    final snapshot = await _journal.readPendingSnapshot();
    if (snapshot == null) return false;

    await FullLibraryBackupRestorer(
      isar: _isar,
      preferences: _preferences,
      documentsDirectoryProvider: _documentsDirectoryProvider,
      recoveryJournal: _journal,
    ).restore(
      snapshot,
      recoveringInterruptedRestore: true,
    );

    return true;
  }
}
