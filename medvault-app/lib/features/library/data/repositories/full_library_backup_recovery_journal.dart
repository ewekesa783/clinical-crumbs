import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Durable marker and snapshot for recovering an interrupted full restore.
///
/// The pending marker is written only after the snapshot has been flushed and
/// renamed into place. A pending marker without a snapshot is treated as a
/// recovery error; callers must not proceed with normal startup.
class FullLibraryBackupRecoveryJournal {
  FullLibraryBackupRecoveryJournal({
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectoryProvider;

  static const _directoryName = 'clinical_crumbs_restore_recovery';
  static const _snapshotName = 'pre_restore_backup.zip';
  static const _pendingName = 'restore_pending';

  Future<Directory> _directory() async {
    final documents = await _documentsDirectoryProvider();
    return Directory('${documents.path}/$_directoryName');
  }

  /// Persists the recovery archive before marking a restore as pending.
  ///
  /// Existing pending recovery data is never overwritten.
  Future<void> savePendingSnapshot(Uint8List snapshotBytes) async {
    final directory = await _directory();
    await directory.create(recursive: true);

    final snapshot = File('${directory.path}/$_snapshotName');
    final pending = File('${directory.path}/$_pendingName');

    if (await pending.exists()) {
      throw StateError(
        'An interrupted restore is already pending recovery. '
        'Recover it before starting another restore.',
      );
    }

    final snapshotTemp = File('${snapshot.path}.tmp');
    final pendingTemp = File('${pending.path}.tmp');

    try {
      if (await snapshotTemp.exists()) {
        await snapshotTemp.delete();
      }
      final handle = await snapshotTemp.open(mode: FileMode.write);
      try {
        await handle.writeFrom(snapshotBytes);
        await handle.flush();
      } finally {
        await handle.close();
      }
      await snapshotTemp.rename(snapshot.path);

      final markerHandle = await pendingTemp.open(mode: FileMode.write);
      try {
        await markerHandle.writeFrom(
          'Clinical Crumbs restore recovery required\n'.codeUnits,
        );
        await markerHandle.flush();
      } finally {
        await markerHandle.close();
      }
      await pendingTemp.rename(pending.path);
    } catch (_) {
      // A snapshot without the pending marker is inert and may be replaced
      // on a later attempt. Never remove an already-pending recovery snapshot.
      rethrow;
    }
  }

  /// Returns the pending snapshot, or null when no recovery is required.
  ///
  /// Throws if the marker exists but the snapshot is missing or empty, so
  /// startup can fail closed rather than initialize over unrecovered data.
  Future<Uint8List?> readPendingSnapshot() async {
    final directory = await _directory();
    final pending = File('${directory.path}/$_pendingName');

    if (!await pending.exists()) return null;

    final snapshot = File('${directory.path}/$_snapshotName');
    if (!await snapshot.exists()) {
      throw StateError(
        'Restore recovery is pending, but its snapshot is missing. '
        'Normal startup must not continue.',
      );
    }

    final bytes = await snapshot.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError(
        'Restore recovery snapshot is empty. Normal startup must not continue.',
      );
    }
    return Uint8List.fromList(bytes);
  }

  /// Clears recovery state after the previous state has been restored and
  /// verified successfully.
  Future<void> clear() async {
    final directory = await _directory();
    final pending = File('${directory.path}/$_pendingName');
    final snapshot = File('${directory.path}/$_snapshotName');
    final pendingTemp = File('${pending.path}.tmp');
    final snapshotTemp = File('${snapshot.path}.tmp');

    // Remove the marker first. If the process stops during cleanup, an
    // orphaned snapshot is inert; a marker must never outlive its snapshot.
    if (await pending.exists()) await pending.delete();
    for (final file in [snapshotTemp, pendingTemp, snapshot]) {
      if (await file.exists()) await file.delete();
    }

    if (await directory.exists() && await directory.list().isEmpty) {
      await directory.delete();
    }
  }
}
