import 'contest_state.dart';

/// Represents a soaring contest.
///
/// A contest is the private source-of-truth aggregate for one radio-controlled
/// soaring event. It tracks multiple independent control states rather than a
/// single status field: an execution lifecycle plus scoring access,
/// administration lock, publication status and visibility, local archive flag,
/// and deletion workflow status. See [ContestStateModel] for the transition
/// rules; use the [stateModel] getter to read and transition them.
class Contest {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String hostVenue;
  final String? city;
  final String? stateProvince;
  final String? country;
  final String? timezone;
  final String? ownerAccountId;
  final DateTime createdAt;
  final DateTime lastModifiedAt;

  /// The contest's execution lifecycle state.
  ContestLifecycleState get lifecycle => stateModel.lifecycle;
  set lifecycle(ContestLifecycleState value) =>
      stateModel.applyLifecycleTransition(value);

  /// Participant self-scoring access (independent of the lifecycle).
  ScoringAccessState get scoringAccess => stateModel.scoringAccess;
  set scoringAccess(ScoringAccessState value) =>
      stateModel.applyScoringAccessTransition(value);

  /// Administration lock state (independent of scoring access).
  AdminLockState get adminLock => stateModel.adminLock;
  set adminLock(AdminLockState value) =>
      stateModel.applyAdminLockTransition(value);

  /// Whether a public projection exists.
  PublicationStatus get publicationStatus => stateModel.publicationStatus;

  /// Visibility of the public projection, or `null` while unpublished.
  VisibilityState? get visibility => stateModel.visibility;
  set visibility(VisibilityState? value) {
    if (value == null) {
      stateModel.visibility = null;
    } else {
      stateModel.applyVisibilityTransition(value);
    }
  }

  /// Whether the local archive flag is set.
  bool get isArchived => stateModel.isArchived;
  set isArchived(bool value) => stateModel.setArchived(value);

  /// Deletion workflow status.
  DeletionStatus get deletionStatus => stateModel.deletionStatus;
  set deletionStatus(DeletionStatus value) =>
      stateModel.applyDeletionStatusTransition(value);

  /// The mutable state model that owns the contest's control dimensions.
  ///
  /// Use its `apply*` methods to validate and perform transitions; the
  /// dimension accessors above delegate to it.
  final ContestStateModel stateModel;

  Contest({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.hostVenue,
    this.city,
    this.stateProvince,
    this.country,
    this.timezone,
    this.ownerAccountId,
    required this.createdAt,
    required this.lastModifiedAt,
    ContestStateModel? stateModel,
  }) : stateModel = stateModel ?? ContestStateModel();
}
