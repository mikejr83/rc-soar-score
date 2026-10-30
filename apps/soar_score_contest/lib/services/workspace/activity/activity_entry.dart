import 'package:equatable/equatable.dart';

/// What a line of the recent-activity list says happened.
enum ActivityKind {
  complete,
  openScoring,
  closeScoring,
  lock,
  unlock,
  publication,
  configurationSaved,
  matrixDrawn,
}

/// One line of the workspace's recent-activity list: what happened, whether
/// the acting account did it, and when.
class ActivityEntry extends Equatable {
  const ActivityEntry({
    required this.id,
    required this.kind,
    required this.byYou,
    required this.at,
  });

  /// The audit event's id, which keeps a row's identity across reloads.
  final String id;

  final ActivityKind kind;

  /// True when the acting account did it. Another actor is not named,
  /// because the audit trail holds only an account id (#345).
  final bool byYou;

  /// When the server logged the event (UTC).
  final DateTime at;

  @override
  List<Object?> get props => [id, kind, byYou, at];
}
