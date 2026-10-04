import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'ids.dart';

ConflictRecord make({
  Id? contest,
  Id? owner,
  bool requiresAction = true,
  ConflictResolution resolution = ConflictResolution.pending,
  ConflictResolutionChoice? choice,
  DateTime? resolvedAt,
}) => ConflictRecord(
  id: exampleId(0xc4),
  contestId: contest,
  ownerAccountId: owner,
  entityType: 'ScorePlaceholder',
  entityId: exampleId(0x301),
  acceptedMutationId: exampleId(0xc3),
  competingMutationId: exampleId(0xc7),
  reasonCode: 'stale_base',
  requiresAction: requiresAction,
  resolution: resolution,
  resolutionChoice: choice,
  createdAt: t0,
  resolvedAt: resolvedAt,
);

void main() {
  final contest = exampleId(0x10);

  group('ConflictRecord', () {
    test('round trips a pending conflict', () {
      final record = make(contest: contest);
      final json = record.toJson();
      expect(json['resolution'], 'Pending');
      expect(json['resolution_choice'], isNull);
      expect(json['requires_action'], true);
      expect(ConflictRecord.fromJson(json), record);
    });

    test('round trips a resolved conflict', () {
      final record = make(
        contest: contest,
        resolution: ConflictResolution.manual,
        choice: ConflictResolutionChoice.tookCompeting,
        resolvedAt: t0,
      );
      expect(record.toJson()['resolution_choice'], 'TookCompeting');
      expect(ConflictRecord.fromJson(record.toJson()), record);
    });

    test('needs exactly one of contest and owner', () {
      expect(() => make(), throwsArgumentError);
      expect(
        () => make(contest: contest, owner: exampleId(1)),
        throwsArgumentError,
      );
    });

    test('a silent record must be Automatic', () {
      expect(
        make(
          contest: contest,
          requiresAction: false,
          resolution: ConflictResolution.automatic,
        ).requiresAction,
        isFalse,
      );
      expect(
        () => make(contest: contest, requiresAction: false),
        throwsArgumentError,
      );
    });

    test('a pending conflict cannot carry a resolution', () {
      expect(
        () => make(
          contest: contest,
          choice: ConflictResolutionChoice.keptAccepted,
        ),
        throwsArgumentError,
      );
      expect(() => make(contest: contest, resolvedAt: t0), throwsArgumentError);
    });

    test('scope follows the owner of the data', () {
      expect(make(contest: contest).syncScope, SyncScope.contest);
      expect(make(owner: exampleId(1)).syncScope, SyncScope.director);
    });

    test('resolution values match the documents', () {
      const resolutions = {
        'Pending': ConflictResolution.pending,
        'Automatic': ConflictResolution.automatic,
        'Manual': ConflictResolution.manual,
      };
      const choices = {
        'KeptAccepted': ConflictResolutionChoice.keptAccepted,
        'TookCompeting': ConflictResolutionChoice.tookCompeting,
        'Merged': ConflictResolutionChoice.merged,
      };
      final base = make(contest: contest).toJson();
      for (final e in resolutions.entries) {
        final json = {...base, 'resolution': e.key};
        expect(ConflictRecord.fromJson(json).resolution, e.value);
      }
      for (final e in choices.entries) {
        final json = {
          ...base,
          'resolution': 'Manual',
          'resolution_choice': e.key,
        };
        expect(ConflictRecord.fromJson(json).resolutionChoice, e.value);
      }
    });
  });
}
