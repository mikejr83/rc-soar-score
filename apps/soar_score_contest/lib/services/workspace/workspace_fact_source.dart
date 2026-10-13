/// A secondary read behind the workspace facts. When one fails the page still
/// loads and the source is listed as unavailable.
enum WorkspaceFactSource {
  scores,
  publication,

  /// The landing tables, read only to name the configuration's table.
  landingTables,
}
