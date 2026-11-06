/// One score the pilot sends for a round.
class ScoreSubmission {
  const ScoreSubmission({
    required this.contestId,
    required this.pilotId,
    required this.round,
    required this.matrixRevision,
    required this.clientMutationId,
    required this.components,
  });

  final String contestId;
  final String pilotId;
  final int round;

  /// The draw revision the entry form was loaded with. The server refuses the
  /// score when the draw changed since.
  final int matrixRevision;

  /// Names this attempt. Sending the same id again never creates a second
  /// score, so a retry after a timeout is safe.
  final String clientMutationId;

  /// The discipline's score components, such as `time_flown` and `landing`.
  final Map<String, Object?> components;
}

/// What the server stored for a flight, in its own numbers, for the
/// read-only card. Every number is the server's calculation.
class ScoreDetails {
  const ScoreDetails({
    this.official = false,
    this.rawScore,
    this.roundScore,
    this.cumulativePenalty,
    this.enteredBy,
  });

  /// True once the contest director has made the score official. Until then
  /// it is the server's calculation and can still change.
  final bool official;
  final String? rawScore;
  final String? roundScore;
  final String? cumulativePenalty;
  final String? enteredBy;
}

/// What the server answered to a [ScoreSubmission].
sealed class SubmitResult {
  const SubmitResult();
}

/// The score is stored. [flightScore] is the server's own calculation.
class ScoreAccepted extends SubmitResult {
  const ScoreAccepted({this.flightScore, this.nextRound, this.details});

  final String? flightScore;
  final ScoreDetails? details;
  final int? nextRound;
}

/// The flight already had a score, from an earlier send or someone else. The
/// stored one stands; [flightScore] is its calculated value.
class ScoreAlreadySubmitted extends SubmitResult {
  const ScoreAlreadySubmitted({this.flightScore, this.details});

  final String? flightScore;
  final ScoreDetails? details;
}

/// The server refused the score. Nothing was stored. [code] is one of
/// `ParticipantErrorCodes`; [fields] names the form fields at fault.
class ScoreRejected extends SubmitResult {
  const ScoreRejected({
    required this.code,
    required this.message,
    this.fields = const [],
  });

  final String code;
  final String message;
  final List<String> fields;
}
