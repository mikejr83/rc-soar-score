/// Why the engine does not sync a scope at all.
enum SyncSkipReason {
  /// An accountless local contest has no remote backup and does not
  /// synchronize until it is claimed.
  accountless,
}
