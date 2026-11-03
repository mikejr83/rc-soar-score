import 'package:equatable/equatable.dart';

/// A published contest as the public sees it: one projection with the
/// participants' display details put back, and standings hidden beyond the
/// round the director allows.
///
/// Everything in it is public. It never carries the publication's owner, a
/// verification email, or a redacted pilot's details.
class PublicPublication extends Equatable {
  PublicPublication({
    required this.publicationId,
    required this.visibility,
    required this.projectionRevision,
    required this.publishedAt,
    required this.contest,
    required this.disciplineType,
    required this.calculationVersion,
    this.resultsHiddenThroughRound,
    Iterable<Object?> participants = const [],
    Iterable<Object?> teams = const [],
    this.matrix,
    Iterable<Object?> scores = const [],
    Iterable<Object?> standingRounds = const [],
    this.calculation,
  }) : participants = List.unmodifiable(participants),
       teams = List.unmodifiable(teams),
       scores = List.unmodifiable(scores),
       standingRounds = List.unmodifiable(standingRounds);

  final String publicationId;

  /// `Unlisted` or `Public`.
  final String visibility;
  final int projectionRevision;
  final DateTime publishedAt;
  final Map<String, Object?> contest;
  final String disciplineType;
  final String calculationVersion;

  /// The last round whose standings are shown, or null when none are hidden.
  final int? resultsHiddenThroughRound;

  /// One entry per pilot: the key, display data and `details`, which is null
  /// for a redacted pilot.
  final List<Object?> participants;
  final List<Object?> teams;
  final Map<String, Object?>? matrix;
  final List<Object?> scores;

  /// The standings after each completed round up to the hiding limit.
  final List<Object?> standingRounds;
  final Map<String, Object?>? calculation;

  Map<String, Object?> toJson() => {
    'publication_id': publicationId,
    'visibility': visibility,
    'projection_revision': projectionRevision,
    'published_at': publishedAt.toIso8601String(),
    'contest': contest,
    'discipline_type': disciplineType,
    'calculation_version': calculationVersion,
    'results_hidden_through_round': resultsHiddenThroughRound,
    'participants': participants,
    'teams': teams,
    'matrix': matrix,
    'scores': scores,
    'standings': {'rounds': standingRounds},
    'calculation': calculation,
  };

  @override
  List<Object?> get props => [
    publicationId,
    visibility,
    projectionRevision,
    publishedAt,
    contest,
    disciplineType,
    calculationVersion,
    resultsHiddenThroughRound,
    participants,
    teams,
    matrix,
    scores,
    standingRounds,
    calculation,
  ];
}

/// A page of the public listing with the 30-day count.
class PublicPublicationList extends Equatable {
  const PublicPublicationList({
    required this.publications,
    required this.recentCount,
  });

  final List<PublicPublicationSummary> publications;

  /// Public contests completed or in progress in the time frame of the list
  /// (the date filters' start bounds, else the last 30 days through the coming Sunday),
  /// whatever the name and venue filters and the page.
  final int recentCount;

  Map<String, Object?> toJson() => {
    'publications': [for (final p in publications) p.toJson()],
    'summary': {'recent_count': recentCount},
  };

  @override
  List<Object?> get props => [publications, recentCount];
}

/// One line of the public listing.
class PublicPublicationSummary extends Equatable {
  const PublicPublicationSummary({
    required this.publicationId,
    required this.publishedAt,
    required this.projectionRevision,
    required this.contest,
    required this.disciplineType,
  });

  final String publicationId;
  final DateTime publishedAt;
  final int projectionRevision;

  /// The projection's contest identity: name, dates, time zone, place.
  final Map<String, Object?> contest;
  final String disciplineType;

  Map<String, Object?> toJson() => {
    'publication_id': publicationId,
    'published_at': publishedAt.toIso8601String(),
    'projection_revision': projectionRevision,
    'contest': contest,
    'discipline_type': disciplineType,
  };

  @override
  List<Object?> get props => [
    publicationId,
    publishedAt,
    projectionRevision,
    contest,
    disciplineType,
  ];
}
