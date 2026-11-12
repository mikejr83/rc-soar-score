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
    this.actorId,
    this.system = false,
    this.pilot,
    this.round,
  });

  /// The audit event's id, which keeps a row's identity across reloads.
  final String id;

  final ActivityKind kind;

  /// True when the acting account did it.
  final bool byYou;

  /// The id of the account that acted, when the event records one. The audit
  /// trail holds no name (#345), so this is what tells accounts apart.
  final String? actorId;

  /// True when the system acted (an automatic publication), not an account.
  final bool system;

  /// When the server logged the event (UTC).
  final DateTime at;

  /// The participant number of the pilot a score correction or retirement
  /// concerns, when the event gives one.
  final int? pilot;

  /// The round a score correction or retirement concerns.
  final int? round;

  @override
  List<Object?> get props => [
    id,
    kind,
    byYou,
    at,
    actorId,
    system,
    pilot,
    round,
  ];
}
