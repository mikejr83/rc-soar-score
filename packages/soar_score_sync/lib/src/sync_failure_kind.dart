/// Why a sync did not complete, as the UI reports it.
enum SyncFailureKind {
  /// No response could be obtained: the device or the service is unreachable.
  offline,

  /// The service refused the token (401). Sign in again; local data is safe.
  tokenExpired,

  /// The service answered with an error, or sent something unreadable.
  serverError,

  /// The protocol or schema version is outside the supported range. The
  /// installation must be updated before it can sync.
  updateRequired,

  /// The installation is revoked or no longer the contest's administration
  /// installation. It can still read and export.
  inactiveInstallation,

  /// The service sent a change this installation cannot store (an entity type
  /// it does not know). The cursor stays before it so nothing is lost; the
  /// installation needs an update.
  unsupportedChange,
}
