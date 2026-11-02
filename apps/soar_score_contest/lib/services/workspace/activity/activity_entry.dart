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
  scoreCorrected,
  pilotRetired,
  pilotReinstated,
}

/// One line of the workspace's recent-activity list: what happened, whether
/// the acting account did it, and when.
class ActivityEntry extends Equatable {
  const ActivityEntry({
    required this.id,
    required this.kind,
    required this.byYou,
    required this.at,
    this.pilot,
    this.round,
  });

  /// The audit event's id, which keeps a row's identity across reloads.
  final String id;

  final ActivityKind kind;

  /// True when the acting account did it. Another actor is not named,
  /// because the audit trail holds only an account id (#345).
  final bool byYou;

  /// When the server logged the event (UTC).
  final DateTime at;

  /// The participant number of the pilot a score correction or retirement
  /// concerns, when the event gives one.
  final int? pilot;

  /// The round a score correction or retirement concerns.
  final int? round;

  @override
  List<Object?> get props => [id, kind, byYou, at, pilot, round];
}
