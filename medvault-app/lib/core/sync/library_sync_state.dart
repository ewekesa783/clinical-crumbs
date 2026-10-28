/// Local knowledge of the shared library's published release state.
///
/// This is separate from per-record sync metadata and personal preferences.
/// Release identifiers remain null until a release manifest is introduced.
class LibrarySyncState {
  const LibrarySyncState({
    this.installedReleaseId,
    this.latestAvailableReleaseId,
    this.lastSuccessfulCheckAt,
    this.lastSuccessfulUpdateAt,
  });

  /// Release currently installed on this device, if known.
  final String? installedReleaseId;

  /// Most recent published release discovered from the server, if known.
  final String? latestAvailableReleaseId;

  /// Time of the last successful server check.
  final DateTime? lastSuccessfulCheckAt;

  /// Time of the last successful shared-content update.
  final DateTime? lastSuccessfulUpdateAt;
}
