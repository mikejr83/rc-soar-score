/// The table groups from the Sync Scope table in `plan/data-model/README.md`.
enum TableGroup {
  /// Contest data, synchronized through the per-contest sequence.
  contest,

  /// A director's own data, synchronized through the per-director sequence.
  director,

  /// Discipline and other system data, synchronized down only.
  system,

  /// Invitations, issued by the service.
  issued,

  /// Calculated results, written only by the calculator.
  derived,

  /// Accounts, publication and installation tables; never on an installation.
  backendOnly,
}
