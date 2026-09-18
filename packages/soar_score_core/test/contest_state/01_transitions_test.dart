import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

DateTime _ts() => DateTime.utc(2026, 9, 18);

Contest _contest({ContestStateModel? stateModel}) => Contest(
      id: 'c1',
      name: 'Test Contest',
      startDate: _ts(),
      endDate: _ts(),
      hostVenue: 'Test Venue',
      createdAt: _ts(),
      lastModifiedAt: _ts(),
      stateModel: stateModel,
    );

void main() {
  group('ContestLifecycleTransitions', () {
    test('created can only transition to configuring', () {
      expect(
        ContestLifecycleTransitions.validTargets(
            ContestLifecycleState.created),
        equals({ContestLifecycleState.configuring}),
      );
      for (final target in ContestLifecycleState.values) {
        if (target == ContestLifecycleState.configuring) continue;
        expect(
            ContestLifecycleTransitions.canTransition(
                ContestLifecycleState.created, target),
            isFalse);
      }
    });

    test('configuring can only transition to ready', () {
      expect(
          ContestLifecycleTransitions.canTransition(
              ContestLifecycleState.configuring,
              ContestLifecycleState.ready),
          isTrue);
      expect(
          ContestLifecycleTransitions.canTransition(
              ContestLifecycleState.configuring,
              ContestLifecycleState.running),
          isFalse,
          reason: 'a valid matrix is required before scoring');
    });

    test('ready can go back to configuring (no scores) or forward to running',
        () {
      expect(
          ContestLifecycleTransitions.canTransition(
              ContestLifecycleState.ready,
              ContestLifecycleState.configuring),
          isTrue);
      expect(
          ContestLifecycleTransitions.canTransition(
              ContestLifecycleState.ready, ContestLifecycleState.running),
          isTrue);
      expect(
          ContestLifecycleTransitions.canTransition(
              ContestLifecycleState.ready, ContestLifecycleState.completed),
          isFalse);
    });

    test('running can only transition to completed', () {
      expect(
          ContestLifecycleTransitions.canTransition(
              ContestLifecycleState.running,
              ContestLifecycleState.completed),
          isTrue);
      for (final target in ContestLifecycleState.values) {
        if (target == ContestLifecycleState.completed) continue;
        expect(
            ContestLifecycleTransitions.canTransition(
                ContestLifecycleState.running, target),
            isFalse);
      }
    });

    test('completed is terminal', () {
      expect(
          ContestLifecycleTransitions.validTargets(
              ContestLifecycleState.completed),
          isEmpty);
    });
  });

  group('Independent control transition tables', () {
    test('scoring access is bidirectional', () {
      expect(ScoringAccessTransitions.canTransition(
          ScoringAccessState.closed, ScoringAccessState.open), isTrue);
      expect(ScoringAccessTransitions.canTransition(
          ScoringAccessState.open, ScoringAccessState.closed), isTrue);
      expect(ScoringAccessTransitions.canTransition(
          ScoringAccessState.closed, ScoringAccessState.closed), isFalse);
      expect(ScoringAccessTransitions.canTransition(
          ScoringAccessState.open, ScoringAccessState.open), isFalse);
    });

    test('admin lock is bidirectional', () {
      expect(AdminLockTransitions.canTransition(AdminLockState.unlocked,
          AdminLockState.locked), isTrue);
      expect(AdminLockTransitions.canTransition(AdminLockState.locked,
          AdminLockState.unlocked), isTrue);
      expect(AdminLockTransitions.canTransition(AdminLockState.locked,
          AdminLockState.locked), isFalse);
    });

    test('publication status is one-way', () {
      expect(PublicationStatusTransitions.canTransition(
          PublicationStatus.unpublished, PublicationStatus.published), isTrue);
      expect(PublicationStatusTransitions.canTransition(
          PublicationStatus.published, PublicationStatus.unpublished), isFalse);
    });

    test('visibility is fully interlinked', () {
      for (final from in VisibilityState.values) {
        for (final to in VisibilityState.values) {
          expect(
            VisibilityTransitions.canTransition(from, to),
            from != to,
            reason: '$from -> $to',
          );
        }
      }
    });

    test('deletion status: unpublished contest', () {
      // Direct deletion is allowed for unpublished local contests.
      expect(DeletionStatusTransitions.canTransition(
          DeletionStatus.none, DeletionStatus.deleted, published: false),
          isTrue);
      expect(DeletionStatusTransitions.canTransition(
          DeletionStatus.none, DeletionStatus.pendingDelete, published: false),
          isTrue);
      expect(DeletionStatusTransitions.canTransition(DeletionStatus.pendingDelete,
          DeletionStatus.deleted, published: false), isTrue);
      expect(DeletionStatusTransitions.canTransition(DeletionStatus.pendingDelete,
          DeletionStatus.restored, published: false), isTrue);
      expect(DeletionStatusTransitions.canTransition(DeletionStatus.restored,
          DeletionStatus.none, published: false), isTrue);
      // Terminal.
      expect(DeletionStatusTransitions.canTransition(DeletionStatus.deleted,
          DeletionStatus.none, published: false), isFalse);
    });

    test('deletion status: published contest', () {
      // Must go through pendingDelete first; never directly deleted.
      expect(DeletionStatusTransitions.canTransition(
          DeletionStatus.none, DeletionStatus.deleted, published: true),
          isFalse);
      expect(DeletionStatusTransitions.canTransition(
          DeletionStatus.none, DeletionStatus.pendingDelete, published: true),
          isTrue);
      expect(DeletionStatusTransitions.canTransition(DeletionStatus.pendingDelete,
          DeletionStatus.deleted, published: true), isTrue);
      expect(DeletionStatusTransitions.canTransition(DeletionStatus.pendingDelete,
          DeletionStatus.restored, published: true), isTrue);
    });
  });


  group('ContestStateModel - lifecycle', () {
    test('full happy path: created -> configuring -> ready -> running -> completed',
        () {
      final model = ContestStateModel();
      expect(model.lifecycle, ContestLifecycleState.created);

      model.applyLifecycleTransition(ContestLifecycleState.configuring);
      model.applyLifecycleTransition(ContestLifecycleState.ready);
      model.applyLifecycleTransition(ContestLifecycleState.running);
      model.applyLifecycleTransition(ContestLifecycleState.completed);

      expect(model.lifecycle, ContestLifecycleState.completed);
    });

    test('ready can go back to configuring', () {
      final model = ContestStateModel(lifecycle: ContestLifecycleState.ready);
      model.applyLifecycleTransition(ContestLifecycleState.configuring);
      expect(model.lifecycle, ContestLifecycleState.configuring);
    });

    test('completion forces participant scoring closed', () {
      final model = ContestStateModel(
        lifecycle: ContestLifecycleState.running,
        scoringAccess: ScoringAccessState.open,
      );
      model.applyLifecycleTransition(ContestLifecycleState.completed);
      expect(model.lifecycle, ContestLifecycleState.completed);
      expect(model.scoringAccess, ScoringAccessState.closed);
    });

    test('illegal transitions throw LifecycleTransitionException', () {
      // Skipped forward.
      expect(
          () => ContestStateModel()
              .applyLifecycleTransition(ContestLifecycleState.running),
          throwsA(isA<LifecycleTransitionException>()));
      // Backward from running.
      expect(
          () => ContestStateModel(lifecycle: ContestLifecycleState.running)
              .applyLifecycleTransition(ContestLifecycleState.ready),
          throwsA(isA<LifecycleTransitionException>()));
      // Backward from completed.
      expect(
          () => ContestStateModel(lifecycle: ContestLifecycleState.completed)
              .applyLifecycleTransition(ContestLifecycleState.running),
          throwsA(isA<LifecycleTransitionException>()));
      // No transition out of completed.
      expect(
          () => ContestStateModel(lifecycle: ContestLifecycleState.completed)
              .applyLifecycleTransition(ContestLifecycleState.created),
          throwsA(isA<LifecycleTransitionException>()));
      // No-op on the same state is rejected.
      expect(
          () => ContestStateModel()
              .applyLifecycleTransition(ContestLifecycleState.created),
          throwsA(isA<LifecycleTransitionException>()));
    });
  });


  group('ContestStateModel - independent controls', () {
    test('scoring access can be opened and closed at any time', () {
      final model = ContestStateModel();
      model.applyScoringAccessTransition(ScoringAccessState.open);
      expect(model.scoringAccess, ScoringAccessState.open);
      model.applyScoringAccessTransition(ScoringAccessState.closed);
      expect(model.scoringAccess, ScoringAccessState.closed);
    });

    test('same-state control transitions are rejected', () {
      expect(
          () => ContestStateModel()
              .applyScoringAccessTransition(ScoringAccessState.closed),
          throwsA(isA<ScoringAccessTransitionException>()));
      expect(
          () => ContestStateModel()
              .applyAdminLockTransition(AdminLockState.unlocked),
          throwsA(isA<AdminLockTransitionException>()));
    });

    test('admin lock can be toggled', () {
      final model = ContestStateModel();
      model.applyAdminLockTransition(AdminLockState.locked);
      expect(model.adminLock, AdminLockState.locked);
      model.applyAdminLockTransition(AdminLockState.unlocked);
      expect(model.adminLock, AdminLockState.unlocked);
    });

    test('publish() is one-way and defaults visibility to private', () {
      final model = ContestStateModel();
      expect(model.visibility, isNull);
      model.publish();
      expect(model.publicationStatus, PublicationStatus.published);
      expect(model.visibility, VisibilityState.private);
      // A second publish is a projection replacement, not a status
      // transition: the table forbids published -> published.
      expect(
          () => model.publish(),
          throwsA(isA<PublicationStatusTransitionException>()));
    });

    test('publishing is blocked by pending deletion', () {
      final model = ContestStateModel(
        deletionStatus: DeletionStatus.pendingDelete,
      );
      expect(
          () => model.publish(),
          throwsA(isA<PublicationStatusTransitionException>()));
    });

    test('visibility can only be changed while published', () {
      // Unpublished: no visibility to transition.
      expect(
          () => ContestStateModel()
              .applyVisibilityTransition(VisibilityState.public),
          throwsA(isA<VisibilityTransitionException>()));

      // Published: any other visibility state is reachable.
      final model = ContestStateModel(
        publicationStatus: PublicationStatus.published,
        visibility: VisibilityState.private,
      );
      model.applyVisibilityTransition(VisibilityState.hidden);
      expect(model.visibility, VisibilityState.hidden);
      model.applyVisibilityTransition(VisibilityState.public);
      expect(model.visibility, VisibilityState.public);
      // No-op is rejected.
      expect(
          () => model.applyVisibilityTransition(VisibilityState.public),
          throwsA(isA<VisibilityTransitionException>()));
    });

    test('archive flag can be set and cleared until deletion', () {
      final model = ContestStateModel();
      model.setArchived(true);
      expect(model.isArchived, isTrue);
      model.setArchived(false);
      expect(model.isArchived, isFalse);
      expect(model.canArchive, isTrue);

      // Archiving is blocked once deleted.
      final deleted = ContestStateModel(
        deletionStatus: DeletionStatus.deleted,
      );
      expect(deleted.canArchive, isFalse);
      expect(
          () => deleted.setArchived(true),
          throwsA(isA<ContestStateTransitionException>()));
    });
  });


  group('ContestStateModel - deletion workflow', () {
    test('unpublished contest can be deleted directly', () {
      final model = ContestStateModel();
      model.applyDeletionStatusTransition(DeletionStatus.deleted);
      expect(model.deletionStatus, DeletionStatus.deleted);
    });

    test('published contest must go through pendingDelete; deletion delists',
        () {
      final model = ContestStateModel(
        publicationStatus: PublicationStatus.published,
        visibility: VisibilityState.public,
      );
      expect(
          () => model.applyDeletionStatusTransition(DeletionStatus.deleted),
          throwsA(isA<DeletionStatusTransitionException>()));

      model.applyDeletionStatusTransition(DeletionStatus.pendingDelete);
      expect(model.deletionStatus, DeletionStatus.pendingDelete);

      model.applyDeletionStatusTransition(DeletionStatus.deleted);
      expect(model.deletionStatus, DeletionStatus.deleted);
      // Deleting a published contest delists its public projection.
      expect(model.publicationStatus, PublicationStatus.unpublished);
      expect(model.visibility, isNull);
    });

    test('pending deletion can be restored', () {
      final model = ContestStateModel(
        publicationStatus: PublicationStatus.published,
        visibility: VisibilityState.public,
        deletionStatus: DeletionStatus.pendingDelete,
      );
      model.applyDeletionStatusTransition(DeletionStatus.restored);
      expect(model.deletionStatus, DeletionStatus.restored);
      // The model retains publication and visibility state.
      expect(model.publicationStatus, PublicationStatus.published);
      expect(model.visibility, VisibilityState.public);

      model.applyDeletionStatusTransition(DeletionStatus.none);
      expect(model.deletionStatus, DeletionStatus.none);
    });

    test('deleted is terminal', () {
      final model = ContestStateModel(deletionStatus: DeletionStatus.deleted);
      expect(
          () => model.applyDeletionStatusTransition(DeletionStatus.restored),
          throwsA(isA<DeletionStatusTransitionException>()));
      expect(
          () => model.applyDeletionStatusTransition(DeletionStatus.none),
          throwsA(isA<DeletionStatusTransitionException>()));
    });
  });


  group('ContestStateModel - derived predicates', () {
    test('canEnterScore requires ready/running, unlocked, and non-deleted',
        () {
      expect(
          ContestStateModel(lifecycle: ContestLifecycleState.ready)
              .canEnterScore,
          isTrue);
      expect(
          ContestStateModel(
              lifecycle: ContestLifecycleState.configuring)
              .canEnterScore,
          isFalse);
      expect(
          ContestStateModel(
            lifecycle: ContestLifecycleState.ready,
            adminLock: AdminLockState.locked,
          ).canEnterScore,
          isFalse);
      expect(
          ContestStateModel(
            lifecycle: ContestLifecycleState.ready,
            deletionStatus: DeletionStatus.pendingDelete,
          ).canEnterScore,
          isFalse);
      expect(
          ContestStateModel(
              deletionStatus: DeletionStatus.deleted)
              .canEnterScore,
          isFalse);
    });

    test('canParticipantSubmitScore requires open scoring access', () {
      expect(
          ContestStateModel(
            lifecycle: ContestLifecycleState.running,
            scoringAccess: ScoringAccessState.open,
          ).canParticipantSubmitScore,
          isTrue);
      expect(
          ContestStateModel(
            lifecycle: ContestLifecycleState.running,
            scoringAccess: ScoringAccessState.closed,
          ).canParticipantSubmitScore,
          isFalse);
      expect(
          ContestStateModel(
            lifecycle: ContestLifecycleState.configuring,
            scoringAccess: ScoringAccessState.open,
          ).canParticipantSubmitScore,
          isFalse);
    });

    test('canModifyConfiguration only while configuring or ready', () {
      expect(
          ContestStateModel(
              lifecycle: ContestLifecycleState.configuring)
              .canModifyConfiguration,
          isTrue);
      expect(
          ContestStateModel(lifecycle: ContestLifecycleState.ready)
              .canModifyConfiguration,
          isTrue);
      expect(
          ContestStateModel()
              .canModifyConfiguration,
          isFalse);
      expect(
          ContestStateModel(lifecycle: ContestLifecycleState.running)
              .canModifyConfiguration,
          isFalse);
    });

    test('canModifyMatrix requires configuring/ready and unlocked', () {
      expect(
          ContestStateModel(lifecycle: ContestLifecycleState.configuring)
              .canModifyMatrix,
          isTrue);
      expect(
          ContestStateModel(
            lifecycle: ContestLifecycleState.ready,
            adminLock: AdminLockState.locked,
          ).canModifyMatrix,
          isFalse);
      expect(
          ContestStateModel(lifecycle: ContestLifecycleState.running)
              .canModifyMatrix,
          isFalse);
    });

    test('canPublish requires running/completed and non-deleted', () {
      expect(
          ContestStateModel(lifecycle: ContestLifecycleState.running)
              .canPublish,
          isTrue);
      expect(
          ContestStateModel(lifecycle: ContestLifecycleState.completed)
              .canPublish,
          isTrue);
      expect(
          ContestStateModel(lifecycle: ContestLifecycleState.configuring)
              .canPublish,
          isFalse);
      expect(
          ContestStateModel(
            lifecycle: ContestLifecycleState.running,
            deletionStatus: DeletionStatus.pendingDelete,
          ).canPublish,
          isFalse);
    });

    test('canChangeVisibility requires published and not pending delete',
        () {
      expect(ContestStateModel().canChangeVisibility, isFalse);
      expect(
          ContestStateModel(
            publicationStatus: PublicationStatus.published,
            visibility: VisibilityState.private,
          ).canChangeVisibility,
          isTrue);
      expect(
          ContestStateModel(
            publicationStatus: PublicationStatus.published,
            visibility: VisibilityState.private,
            deletionStatus: DeletionStatus.pendingDelete,
          ).canChangeVisibility,
          isFalse);
    });

    test('canRequestDeletion only from none; canRestore only from pending',
        () {
      expect(ContestStateModel().canRequestDeletion, isTrue);
      expect(
          ContestStateModel(
              deletionStatus: DeletionStatus.pendingDelete)
              .canRequestDeletion,
          isFalse);
      expect(
          ContestStateModel(
              deletionStatus: DeletionStatus.pendingDelete)
              .canRestore,
          isTrue);
      expect(ContestStateModel().canRestore, isFalse);
      expect(
          ContestStateModel(deletionStatus: DeletionStatus.deleted)
              .canRestore,
          isFalse);
    });
  });


  group('Contest - state model wiring', () {
    test('a new Contest has default state', () {
      final contest = _contest();
      expect(contest.lifecycle, ContestLifecycleState.created);
      expect(contest.scoringAccess, ScoringAccessState.closed);
      expect(contest.adminLock, AdminLockState.unlocked);
      expect(contest.publicationStatus, PublicationStatus.unpublished);
      expect(contest.visibility, isNull);
      expect(contest.isArchived, isFalse);
      expect(contest.deletionStatus, DeletionStatus.none);
    });

    test('Contest delegates state accessors and mutations to the model', () {
      final contest = _contest();
      contest.lifecycle = ContestLifecycleState.configuring;
      expect(contest.lifecycle, ContestLifecycleState.configuring);

      contest.scoringAccess = ScoringAccessState.open;
      expect(contest.scoringAccess, ScoringAccessState.open);

      contest.stateModel.publish();
      expect(contest.publicationStatus, PublicationStatus.published);
      expect(contest.visibility, VisibilityState.private);
    });

    test('Contest accepts an injected state model', () {
      final model = ContestStateModel(
        lifecycle: ContestLifecycleState.running,
        scoringAccess: ScoringAccessState.open,
      );
      final contest = _contest(stateModel: model);
      expect(identical(contest.stateModel, model), isTrue);
      expect(contest.lifecycle, ContestLifecycleState.running);
      expect(contest.scoringAccess, ScoringAccessState.open);
    });
  });
}

