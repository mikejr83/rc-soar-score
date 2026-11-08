import 'package:soar_score_core/soar_score_core.dart' as core;

/// What one exchange with the service depended on when it was sent: the
/// profile generation, and the sign-in its data was sent under.
class SyncPin {
  const SyncPin({required this.generation, required this.owner, this.lease});

  final int generation;

  /// The account whose data the exchange carried; null for system data.
  final core.Id? owner;

  /// The sign-in the exchange was sent under; null when none was current.
  final int? lease;
}
