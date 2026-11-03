import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/admin_lock.dart';
import '../../enums/lifecycle_state.dart';
import '../../enums/scoring_access.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'contest.g.dart';

/// The private source-of-truth event aggregate root.
///
/// The independent control states ([lifecycleState], [scoringAccess],
/// [adminLock] and results hiding) never imply one another. See
/// `plan/data-model/entities/contest.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class Contest extends Equatable implements Synchronizable {
  Contest({
    required this.id,
    required String name,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String timezone,
    this.host,
    this.city,
    this.state,
    this.country,
    this.ownerAccountId,
    this.lifecycleState = LifecycleState.created,
    this.scoringAccess = ScoringAccess.closed,
    this.adminLock = AdminLock.unlocked,
    this.resultsHiddenThroughRound,
    DateTime? resultsHiddenAt,
    this.localArchive = false,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.revision = 0,
  }) : name = requireNotBlank(name, 'name'),
       timezone = requireNotBlank(timezone, 'timezone'),
       startDateTime = startDateTime.toUtc(),
       endDateTime = endDateTime.toUtc(),
       resultsHiddenAt = resultsHiddenAt?.toUtc(),
       createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc() {
    if (this.endDateTime.isBefore(this.startDateTime)) {
      throw ArgumentError.value(
        endDateTime,
        'endDateTime',
        'must not precede startDateTime',
      );
    }
    if ((resultsHiddenThroughRound == null) != (resultsHiddenAt == null)) {
      throw ArgumentError(
        'results_hidden_through_round and results_hidden_at are set together',
      );
    }
    if (resultsHiddenThroughRound != null && resultsHiddenThroughRound! < 1) {
      throw ArgumentError.value(
        resultsHiddenThroughRound,
        'resultsHiddenThroughRound',
        'must be at least 1',
      );
    }
    requireNonNegative(revision, 'revision');
  }

  factory Contest.fromJson(Map<String, Object?> json) =>
      _$ContestFromJson(json);

  /// How long hiding lasts after [resultsHiddenAt] if nobody turns it off.
  static const Duration hidingLifetime = Duration(hours: 24);

  @override
  final Id id;

  /// Contest name.
  final String name;

  /// Start, stored in UTC and shown in [timezone].
  final DateTime startDateTime;

  /// End, stored in UTC and shown in [timezone].
  final DateTime endDateTime;

  /// IANA timezone name, stored at creation.
  final String timezone;

  final String? host;
  final String? city;
  final String? state;
  final String? country;

  /// The owning account; null for anonymous or local contests.
  final Id? ownerAccountId;

  final LifecycleState lifecycleState;
  final ScoringAccess scoringAccess;
  final AdminLock adminLock;

  /// The round through which overall scores and placing are shown; null when
  /// results are not hidden.
  final int? resultsHiddenThroughRound;

  /// When hiding was turned on; set exactly when
  /// [resultsHiddenThroughRound] is.
  final DateTime? resultsHiddenAt;

  /// Local to the installation and never synchronized.
  final bool localArchive;

  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  final int revision;

  @override
  String get entityType => 'Contest';

  @override
  SyncScope get syncScope => SyncScope.contest;

  bool get resultsHidden => resultsHiddenThroughRound != null;

  /// When hiding runs out (UTC); null when results are not hidden.
  DateTime? get hidingEndsAt => resultsHiddenAt?.add(hidingLifetime);

  /// Whether hiding has run its 24 hours by [now].
  bool hidingExpiredAt(DateTime now) =>
      hidingEndsAt != null && !now.toUtc().isBefore(hidingEndsAt!);

  /// A copy with a changed lifecycle or control value and update time.
  ///
  /// [clearResultsHiding] ends results hiding. [hideResultsThroughRound]
  /// turns it on, or moves it, to that round, stamped [updatedAt];
  /// [clearResultsHiding] wins if both are given. The revision is kept: the
  /// repository bumps it when the copy is saved.
  Contest copyWithState({
    LifecycleState? lifecycleState,
    ScoringAccess? scoringAccess,
    AdminLock? adminLock,
    bool clearResultsHiding = false,
    int? hideResultsThroughRound,
    required DateTime updatedAt,
  }) => Contest(
    id: id,
    name: name,
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    timezone: timezone,
    host: host,
    city: city,
    state: state,
    country: country,
    ownerAccountId: ownerAccountId,
    lifecycleState: lifecycleState ?? this.lifecycleState,
    scoringAccess: scoringAccess ?? this.scoringAccess,
    adminLock: adminLock ?? this.adminLock,
    resultsHiddenThroughRound: clearResultsHiding
        ? null
        : hideResultsThroughRound ?? resultsHiddenThroughRound,
    resultsHiddenAt: clearResultsHiding
        ? null
        : hideResultsThroughRound != null
        ? updatedAt
        : resultsHiddenAt,
    localArchive: localArchive,
    createdAt: createdAt,
    updatedAt: updatedAt,
    revision: revision,
  );

  Map<String, Object?> toJson() => _$ContestToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    startDateTime,
    endDateTime,
    timezone,
    host,
    city,
    state,
    country,
    ownerAccountId,
    lifecycleState,
    scoringAccess,
    adminLock,
    resultsHiddenThroughRound,
    resultsHiddenAt,
    localArchive,
    createdAt,
    updatedAt,
    revision,
  ];
}
