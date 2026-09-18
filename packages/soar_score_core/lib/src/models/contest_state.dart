/// State model for a contest.
///
/// A contest has one execution lifecycle and several independent controls.
/// Each dimension has its own set of states and an explicit transition table.
/// Keeping these dimensions separate prevents a publication change, scoring
/// pause, or delete request from being mistaken for a change in the
/// contest's execution state.
///
/// See `plan/architecture-requirements/contest-state-and-transitions.md` and
/// `plan/architecture-requirements/contest-visibility-state.md` for the
/// authoritative business rules.
library;

/// The contest's execution lifecycle: how far the contest has progressed.
///
/// The lifecycle is monotonic:
///
/// ```text
/// created -> configuring -> ready -> running -> completed
/// ```
///
/// There is one backward exception, from `ready` to `configuring`, taken when
/// a configuration or matrix change invalidates the current matrix and no
/// score exists. There is no ordinary transition back from `running` or
/// `completed`.
enum ContestLifecycleState {
  /// The contest has its minimum identity and location data, but no contest
  /// configuration has started.
  created,

  /// The director is selecting the discipline and configuring participants,
  /// scoring, rules, and draw options.
  configuring,

  /// A valid flight matrix exists and no score has been submitted.
  ready,

  /// At least one score has been submitted and the contest has not been
  /// completed.
  running,

  /// Contest execution has ended. The result is available for final
  /// validation and publication.
  completed,
}

/// The transition table for [ContestLifecycleState].
///
/// | From        | To           | Condition                                                        |
/// | ----------- | ------------ | ---------------------------------------------------------------- |
/// | `created`    | `configuring`| A discipline is selected or another configuration mutation is accepted. |
/// | `configuring`| `ready`      | Required configuration is valid and a valid flight matrix exists.        |
/// | `ready`      | `configuring`| A configuration/matrix change invalidates the matrix and no score exists. |
/// | `ready`      | `running`    | The first score submission is accepted.                              |
/// | `running`    | `completed`  | The director completes the contest, or an accepted completion condition is met. |
///
/// `configuring -> running` is not allowed: a valid matrix is required before
/// scoring.
class ContestLifecycleTransitions {
  const ContestLifecycleTransitions._();

  /// The states reachable from [from] in one step.
  static Set<ContestLifecycleState> validTargets(
      ContestLifecycleState from) {
    switch (from) {
      case ContestLifecycleState.created:
        return const {ContestLifecycleState.configuring};
      case ContestLifecycleState.configuring:
        return const {ContestLifecycleState.ready};
      case ContestLifecycleState.ready:
        return const {
          ContestLifecycleState.configuring,
          ContestLifecycleState.running,
        };
      case ContestLifecycleState.running:
        return const {ContestLifecycleState.completed};
      case ContestLifecycleState.completed:
        return const {};
    }
  }

  /// Whether [to] is a legal one-step transition from [from].
  static bool canTransition(
      ContestLifecycleState from, ContestLifecycleState to) {
    return validTargets(from).contains(to);
  }
}


/// Controls participant self-scoring. Independent of the lifecycle.
enum ScoringAccessState {
  /// Participants cannot submit scores. The director or an authorized local
  /// operator may enter scores when the lifecycle and lock rules permit it.
  closed,

  /// Participants and authorized helpers may submit scores when the lifecycle
  /// and lock rules permit it.
  open,
}

/// The transition table for [ScoringAccessState]: `closed <-> open`.
class ScoringAccessTransitions {
  const ScoringAccessTransitions._();

  /// The states reachable from [from] in one step.
  static Set<ScoringAccessState> validTargets(ScoringAccessState from) {
    switch (from) {
      case ScoringAccessState.closed:
        return const {ScoringAccessState.open};
      case ScoringAccessState.open:
        return const {ScoringAccessState.closed};
    }
  }

  /// Whether [to] is a legal one-step transition from [from].
  static bool canTransition(ScoringAccessState from, ScoringAccessState to) {
    return validTargets(from).contains(to);
  }
}

/// The administration lock. Independent of scoring access. It prevents
/// modifications to contest configuration, participation, matrix
/// assignments, and scores. A locked contest may still be viewed and
/// published if the publication rules permit it.
enum AdminLockState {
  /// Authorized changes are allowed under the lifecycle rules.
  unlocked,

  /// Mutations covered by the lock are rejected.
  locked,
}

/// The transition table for [AdminLockState]: `unlocked <-> locked`.
class AdminLockTransitions {
  const AdminLockTransitions._();

  /// The states reachable from [from] in one step.
  static Set<AdminLockState> validTargets(AdminLockState from) {
    switch (from) {
      case AdminLockState.unlocked:
        return const {AdminLockState.locked};
      case AdminLockState.locked:
        return const {AdminLockState.unlocked};
    }
  }

  /// Whether [to] is a legal one-step transition from [from].
  static bool canTransition(AdminLockState from, AdminLockState to) {
    return validTargets(from).contains(to);
  }
}

/// Whether a public projection of the contest exists.
///
/// Publication is an operation, not a lifecycle state. It may occur while
/// the contest is `running` or `completed`.
enum PublicationStatus {
  /// No public projection exists.
  unpublished,

  /// A public projection exists and records the source private revision.
  published,
}

/// The transition table for [PublicationStatus]:
/// `unpublished -> published` (one-way).
class PublicationStatusTransitions {
  const PublicationStatusTransitions._();

  /// The states reachable from [from] in one step.
  static Set<PublicationStatus> validTargets(PublicationStatus from) {
    switch (from) {
      case PublicationStatus.unpublished:
        return const {PublicationStatus.published};
      case PublicationStatus.published:
        return const {};
    }
  }

  /// Whether [to] is a legal one-step transition from [from].
  static bool canTransition(PublicationStatus from, PublicationStatus to) {
    return validTargets(from).contains(to);
  }
}


/// How a published projection is visible to the public site.
///
/// Visibility is independent of publication status and of the lifecycle.
/// A contest that is [PublicationStatus.unpublished] has no visibility.
enum VisibilityState {
  /// Not searchable or publicly viewable. The first publish defaults to
  /// private.
  private,

  /// Not searchable or generally listed, but available to authorized
  /// participants.
  hidden,

  /// Searchable and viewable without an account.
  public,
}

/// The transition table for [VisibilityState]:
/// `private <-> hidden`, `private <-> public`, `hidden <-> public`.
class VisibilityTransitions {
  const VisibilityTransitions._();

  /// The states reachable from [from] in one step.
  static Set<VisibilityState> validTargets(VisibilityState from) {
    switch (from) {
      case VisibilityState.private:
        return const {VisibilityState.hidden, VisibilityState.public};
      case VisibilityState.hidden:
        return const {VisibilityState.private, VisibilityState.public};
      case VisibilityState.public:
        return const {VisibilityState.private, VisibilityState.hidden};
    }
  }

  /// Whether [to] is a legal one-step transition from [from].
  static bool canTransition(VisibilityState from, VisibilityState to) {
    return validTargets(from).contains(to);
  }
}

/// The deletion workflow. Deletion is an administrative workflow, not a
/// normal execution state.
enum DeletionStatus {
  /// No deletion request exists.
  none,

  /// A contest published at least once was delisted and awaits administrator
  /// approval. No scoring or ordinary editing is allowed.
  pendingDelete,

  /// An administrator denied the request. The contest and its prior
  /// publication and visibility state are restored, and the restoration is
  /// retained as audit history.
  restored,

  /// An administrator approved removal, or an unpublished local contest was
  /// deleted by its director. This is terminal.
  deleted,
}

/// The transition table for [DeletionStatus]:
///
/// ```text
/// none -> pendingDelete -> deleted
///                      \-> restored -> none
///
/// none -> deleted   (unpublished, director-owned local contest, after
///                    confirmation)
/// ```
class DeletionStatusTransitions {
  const DeletionStatusTransitions._();

  /// The states reachable from [from] in one step.
  ///
  /// [published] controls whether the direct `none -> deleted` transition is
  /// allowed: a contest that has ever been published must first go through
  /// [DeletionStatus.pendingDelete] and administrator approval.
  static Set<DeletionStatus> validTargets(
    DeletionStatus from, {
    required bool published,
  }) {
    switch (from) {
      case DeletionStatus.none:
        return published
            ? const {DeletionStatus.pendingDelete}
            : const {DeletionStatus.pendingDelete, DeletionStatus.deleted};
      case DeletionStatus.pendingDelete:
        return const {
          DeletionStatus.deleted,
          DeletionStatus.restored,
        };
      case DeletionStatus.restored:
        return const {DeletionStatus.none};
      case DeletionStatus.deleted:
        return const {};
    }
  }

  /// Whether [to] is a legal one-step transition from [from].
  static bool canTransition(
    DeletionStatus from,
    DeletionStatus to, {
    required bool published,
  }) {
    return validTargets(from, published: published).contains(to);
  }
}

/// Raised when a requested state transition violates the transition tables.
class ContestStateTransitionException implements Exception {
  /// Human-readable description of the rejected transition.
  final String message;

  const ContestStateTransitionException(this.message);

  @override
  String toString() => 'ContestStateTransitionException: $message';
}

/// Thrown when the requested [ContestLifecycleState] transition is illegal.
class LifecycleTransitionException extends ContestStateTransitionException {
  final ContestLifecycleState from;
  final ContestLifecycleState to;

  LifecycleTransitionException(this.from, this.to)
      : super(
            'Invalid lifecycle transition: $from -> $to. '
            'Valid targets from $from: '
            '${ContestLifecycleTransitions.validTargets(from)}');
}

/// Thrown when the requested [ScoringAccessState] transition is illegal.
class ScoringAccessTransitionException extends ContestStateTransitionException {
  final ScoringAccessState from;
  final ScoringAccessState to;

  ScoringAccessTransitionException(this.from, this.to)
      : super(
            'Invalid scoring access transition: $from -> $to. '
            'Valid targets from $from: '
            '${ScoringAccessTransitions.validTargets(from)}');
}

/// Thrown when the requested [AdminLockState] transition is illegal.
class AdminLockTransitionException extends ContestStateTransitionException {
  final AdminLockState from;
  final AdminLockState to;

  AdminLockTransitionException(this.from, this.to)
      : super(
            'Invalid administration lock transition: $from -> $to. '
            'Valid targets from $from: '
            '${AdminLockTransitions.validTargets(from)}');
}

/// Thrown when the requested [PublicationStatus] transition is illegal.
class PublicationStatusTransitionException
    extends ContestStateTransitionException {
  final PublicationStatus from;
  final PublicationStatus to;

  PublicationStatusTransitionException(this.from, this.to)
      : super(
            'Invalid publication status transition: $from -> $to. '
            'Valid targets from $from: '
            '${PublicationStatusTransitions.validTargets(from)}');
}

/// Thrown when the requested [VisibilityState] transition is illegal.
class VisibilityTransitionException extends ContestStateTransitionException {
  final VisibilityState from;
  final VisibilityState to;

  VisibilityTransitionException(this.from, this.to)
      : super(
            'Invalid visibility transition: $from -> $to. '
            'Valid targets from $from: '
            '${VisibilityTransitions.validTargets(from)}');
}

/// Thrown when the requested [DeletionStatus] transition is illegal.
class DeletionStatusTransitionException
    extends ContestStateTransitionException {
  final DeletionStatus from;
  final DeletionStatus to;
  final bool published;

  DeletionStatusTransitionException(this.from, this.to, this.published)
      : super(
            'Invalid deletion status transition: $from -> $to'
            '${published ? ' (published contest)' : ''}. '
            'Valid targets from $from: '
            '${DeletionStatusTransitions.validTargets(from, published: published)}');
}

/// A mutable, pure-in-memory representation of a contest's state
/// dimensions and the rules that constrain them.
///
/// Each dimension is independent: changing publication status, visibility,
/// the administration lock, or scoring access never changes the execution
/// lifecycle, and vice versa. The coupling rules are the invariants in
/// `plan/architecture-requirements/contest-state-and-transitions.md`:
///
/// * Completion forces participant scoring closed.
/// * Score submission is only accepted in `ready` or `running`, and the first
///   accepted score changes `ready` to `running` atomically with the score
///   mutation.
/// * Pending deletion prevents scoring and publication updates.
///
/// The `apply*` methods validate against the transition tables and throw the
/// matching exception on an illegal move. They do not perform persistence,
/// revision bookkeeping, or actor/authority validation — those are concerns of
/// the service/synchronization layers, which must record the actor, authority,
/// source installation, base revision, resulting revision, and time for every
/// accepted transition.
class ContestStateModel {
  /// Execution lifecycle of the contest.
  ContestLifecycleState lifecycle;

  /// Participant self-scoring access.
  ScoringAccessState scoringAccess;

  /// Administration lock state.
  AdminLockState adminLock;

  /// Whether a public projection exists.
  PublicationStatus publicationStatus;

  /// Visibility of the public projection, or `null` while the contest is
  /// [PublicationStatus.unpublished].
  ///
  /// The first publish defaults to [VisibilityState.private].
  VisibilityState? visibility;

  /// Deletion workflow status.
  DeletionStatus deletionStatus;

  /// Whether the local archive flag is currently set.
  ///
  /// Local archiving is a storage/display flag for an offline or
  /// director-owned contest. It hides the contest from ordinary local
  /// selection without deleting data and is not the same as a publicly
  /// published historical record.
  bool isArchived;

  /// Whether the director owns this local (offline) copy of the contest.
  ///
  /// Only unpublished, director-owned local contests may transition directly
  /// from [DeletionStatus.none] to [DeletionStatus.deleted].
  final bool isDirectorOwnedLocal;

  ContestStateModel({
    this.lifecycle = ContestLifecycleState.created,
    this.scoringAccess = ScoringAccessState.closed,
    this.adminLock = AdminLockState.unlocked,
    this.publicationStatus = PublicationStatus.unpublished,
    this.visibility,
    this.deletionStatus = DeletionStatus.none,
    this.isArchived = false,
    this.isDirectorOwnedLocal = false,
  });

  /// Whether a public projection exists.
  bool get isPublished => publicationStatus == PublicationStatus.published;

  /// The current visibility, or `null` while unpublished.
  VisibilityState? get currentVisibility => visibility;

  /// Whether participant scoring is blocked by the deletion workflow.
  ///
  /// Pending deletion prevents scoring. A deleted contest accepts no
  /// submissions at all.
  bool get isScoringBlockedByDeletion =>
      deletionStatus == DeletionStatus.pendingDelete ||
      deletionStatus == DeletionStatus.deleted;

  /// Whether a score submission may be accepted.
  ///
  /// Requires the lifecycle to be `ready` or `running`, the administration
  /// lock to be released, and no deletion block.
  bool get canEnterScore =>
      (lifecycle == ContestLifecycleState.ready ||
          lifecycle == ContestLifecycleState.running) &&
      adminLock == AdminLockState.unlocked &&
      !isScoringBlockedByDeletion;

  /// Whether participant self-scoring is currently permitted.
  ///
  /// Requires [canEnterScore] plus open scoring access.
  bool get canParticipantSubmitScore =>
      canEnterScore && scoringAccess == ScoringAccessState.open;

  /// Whether contest configuration may be modified.
  ///
  /// `created` allows only minimum identity and location data (discipline
  /// selection and similar configuration mutations are not available);
  /// `configuring` and `ready` permit configuration changes (a matrix change
  /// in `ready` must not invalidate the matrix while scores exist — that
  /// check is data-dependent and handled by the service layer); `running`
  /// and `completed` fix participation, teams, roles, draw mode, groups per
  /// round, discipline, and discipline scoring rules.
  bool get canModifyConfiguration =>
      lifecycle == ContestLifecycleState.configuring ||
      lifecycle == ContestLifecycleState.ready;

  /// Whether a participation, matrix, or team change is permitted.
  ///
  /// Participation and matrix changes are allowed while `configuring` or
  /// `ready` and not administration-locked. In `running`, lane assignments may
  /// change only for groups without scores (a data-dependent check the
  /// service layer performs); in `completed`, no new rounds, participation,
  /// or matrix changes are allowed.
  bool get canModifyMatrix =>
      (lifecycle == ContestLifecycleState.configuring ||
          lifecycle == ContestLifecycleState.ready) &&
      adminLock == AdminLockState.unlocked;

  /// Whether the contest may be published.
  ///
  /// Publishing may occur while `running` or `completed` and is blocked by
  /// the deletion workflow. A later publish replaces the public projection
  /// atomically and is allowed from the `published` status.
  bool get canPublish =>
      (lifecycle == ContestLifecycleState.running ||
          lifecycle == ContestLifecycleState.completed) &&
      deletionStatus != DeletionStatus.pendingDelete &&
      deletionStatus != DeletionStatus.deleted;

  /// Whether visibility may be changed.
  ///
  /// Visibility only exists once the contest is published, and changing it
  /// never modifies the private contest data.
  bool get canChangeVisibility =>
      isPublished && deletionStatus != DeletionStatus.pendingDelete;

  /// Whether the local archive flag may be set or cleared.
  ///
  /// Local archiving is a storage/display flag available at any lifecycle
  /// state. It is only blocked once deletion has been approved.
  bool get canArchive => deletionStatus != DeletionStatus.deleted;

  /// Whether a deletion request may be initiated.
  ///
  /// A published contest enters [DeletionStatus.pendingDelete] after its
  /// public projection is delisted; an unpublished, director-owned local
  /// contest may be deleted directly after confirmation.
  bool get canRequestDeletion => deletionStatus == DeletionStatus.none;

  /// Whether a pending deletion may be restored by an administrator.
  bool get canRestore => deletionStatus == DeletionStatus.pendingDelete;

  /// Sets or clears the local archive flag.
  ///
  /// Allowed at any lifecycle state unless the contest has been deleted.
  void setArchived(bool value) {
    if (deletionStatus == DeletionStatus.deleted) {
      throw const ContestStateTransitionException(
          'Cannot archive a deleted contest');
    }
    isArchived = value;
  }

  /// Applies a lifecycle transition, throwing
  /// [LifecycleTransitionException] when the table forbids it.
  void applyLifecycleTransition(ContestLifecycleState to) {
    if (!ContestLifecycleTransitions.canTransition(lifecycle, to)) {
      throw LifecycleTransitionException(lifecycle, to);
    }
    lifecycle = to;
    // Completion forces participant scoring closed (invariant 5).
    if (to == ContestLifecycleState.completed) {
      scoringAccess = ScoringAccessState.closed;
    }
  }

  /// Applies a scoring access transition, throwing
  /// [ScoringAccessTransitionException] when the table forbids it.
  void applyScoringAccessTransition(ScoringAccessState to) {
    if (!ScoringAccessTransitions.canTransition(scoringAccess, to)) {
      throw ScoringAccessTransitionException(scoringAccess, to);
    }
    scoringAccess = to;
  }

  /// Applies an administration lock transition, throwing
  /// [AdminLockTransitionException] when the table forbids it.
  void applyAdminLockTransition(AdminLockState to) {
    if (!AdminLockTransitions.canTransition(adminLock, to)) {
      throw AdminLockTransitionException(adminLock, to);
    }
    adminLock = to;
  }

  /// Publishes the contest, transitioning
  /// [PublicationStatus.unpublished] to [PublicationStatus.published] and
  /// defaulting visibility to [VisibilityState.private].
  ///
  /// Throws [PublicationStatusTransitionException] if the contest is already
  /// published (a later publish is a projection replacement, not a status
  /// transition) or if the deletion workflow blocks publication.
  void publish() {
    if (deletionStatus == DeletionStatus.pendingDelete ||
        deletionStatus == DeletionStatus.deleted) {
      throw PublicationStatusTransitionException(
          publicationStatus, publicationStatus);
    }
    if (!PublicationStatusTransitions.canTransition(
        publicationStatus, PublicationStatus.published)) {
      throw PublicationStatusTransitionException(
          publicationStatus, PublicationStatus.published);
    }
    publicationStatus = PublicationStatus.published;
    visibility = VisibilityState.private;
  }

  /// Applies a visibility transition, throwing
  /// [VisibilityTransitionException] when the table forbids it.
  ///
  /// The contest must be published first.
  void applyVisibilityTransition(VisibilityState to) {
    if (!isPublished || visibility == null) {
      throw VisibilityTransitionException(
          VisibilityState.private, to);
    }
    final from = visibility!;
    if (!VisibilityTransitions.canTransition(from, to)) {
      throw VisibilityTransitionException(from, to);
    }
    visibility = to;
  }

  /// Applies a deletion status transition, throwing
  /// [DeletionStatusTransitionException] when the table forbids it.
  ///
  /// The direct [DeletionStatus.none] -> [DeletionStatus.deleted] transition
  /// is only allowed for unpublished, director-owned local contests.
  /// Approving deletion of a published contest delists its public
  /// projection; the retained public history is removed only by the
  /// administrator-approval workflow.
  void applyDeletionStatusTransition(DeletionStatus to) {
    if (!DeletionStatusTransitions.canTransition(
      deletionStatus,
      to,
      published: isPublished,
    )) {
      throw DeletionStatusTransitionException(
          deletionStatus, to, isPublished);
    }
    deletionStatus = to;
    // Deleting a published contest delists its public projection.
    if (to == DeletionStatus.deleted) {
      publicationStatus = PublicationStatus.unpublished;
      visibility = null;
    }
    // Restoration returns the contest to its prior execution lifecycle and
    // prior publication and visibility state. The model retains that state
    // unchanged; the audit layer records the restoration decision.
  }

  @override
  String toString() =>
      'ContestStateModel(lifecycle: $lifecycle, scoringAccess: $scoringAccess, '
      'adminLock: $adminLock, publicationStatus: $publicationStatus, '
      'visibility: $visibility, deletionStatus: $deletionStatus, '
      'isArchived: $isArchived)';
}

