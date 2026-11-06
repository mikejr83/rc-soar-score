import 'package:equatable/equatable.dart';

import '../enums/authority.dart';
import '../models/id.dart';
import 'calculated_flight.dart';

/// A score as the participant is shown it: the pilot's own preliminary
/// submission, or the director's official score that stands over it.
class ParticipantSubmission extends Equatable {
  const ParticipantSubmission({
    required this.assignmentId,
    required this.round,
    required this.components,
    required this.revision,
    required this.enteredAt,
    required this.calculated,
    required this.authority,
    this.nextRound,
    this.replayed = false,
  });

  final Id assignmentId;

  /// The ordinal of the round the score is for.
  final int round;

  /// The components as submitted (or as the director entered them).
  final Map<String, Object?> components;

  /// The slot's score revision after this score.
  final int revision;

  /// When the score was accepted.
  final DateTime enteredAt;
  final CalculatedFlight calculated;

  /// Who made the score: [Authority.participant] for the pilot's own
  /// preliminary submission, [Authority.director] for an official score.
  final Authority authority;

  /// The next round the pilot has to score, or null after the last one.
  final int? nextRound;

  /// True when this answers a repeat of an earlier request (same client
  /// mutation id): nothing was stored again.
  final bool replayed;

  @override
  List<Object?> get props => [
    assignmentId,
    round,
    components,
    revision,
    enteredAt,
    calculated,
    authority,
    nextRound,
    replayed,
  ];
}

/// One field a submission was refused for. [code] is `required`,
/// `wrong_type`, `out_of_range` or `not_allowed`.
class SubmissionFieldError extends Equatable {
  const SubmissionFieldError(this.field, this.code);

  final String field;
  final String code;

  @override
  List<Object?> get props => [field, code];
}

/// A participant's score submission was refused. [code] is one of the
/// participant error codes (`score_already_submitted`, `validation_failed`,
/// `stale_matrix`, `out_of_order`, `mutation_conflict`); [statusCode] is the
/// HTTP status it is answered with.
class ParticipantSubmissionRefusal extends Error {
  ParticipantSubmissionRefusal(
    this.statusCode,
    this.code,
    this.message, {
    this.fieldErrors = const [],
    this.accepted,
  });

  final int statusCode;
  final String code;
  final String message;
  final List<SubmissionFieldError> fieldErrors;

  /// With `score_already_submitted`: the score that was accepted first.
  final ParticipantSubmission? accepted;

  @override
  String toString() => 'ParticipantSubmissionRefusal($code): $message';
}
