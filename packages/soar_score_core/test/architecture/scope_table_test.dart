import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../support/example_files.dart';

/// One entity's decoder and the sync scopes it may have, from the Sync Scope
/// table in `plan/data-model/README.md`.
///
/// Referencing every class through `package:soar_score_core/soar_score_core.dart`
/// also audits the public exports. `LandingResult` is the one entity with no
/// scope of its own: it travels with its `LandingTable`.
class _Expected {
  const _Expected(this.entity, this.decode, this.scopes);

  final String entity;
  final Object Function(Map<String, Object?>) decode;
  final Set<SyncScope> scopes;
}

final _table = <_Expected>[
  _Expected('Account', Account.fromJson, {SyncScope.backendOnly}),
  _Expected('AccountIdentity', AccountIdentity.fromJson, {
    SyncScope.backendOnly,
  }),
  _Expected('AccountPublicProfile', AccountPublicProfile.fromJson, {
    SyncScope.backendOnly,
  }),
  _Expected('AuditEvent', AuditEvent.fromJson, {
    SyncScope.contest,
    SyncScope.director,
    SyncScope.backendOnly,
  }),
  _Expected('ConflictRecord', ConflictRecord.fromJson, {
    SyncScope.contest,
    SyncScope.director,
  }),
  _Expected('Contest', Contest.fromJson, {SyncScope.contest}),
  _Expected('ContestConfigurationPreset', ContestConfigurationPreset.fromJson, {
    SyncScope.director,
  }),
  _Expected(
    'ContestConfigurationRevision',
    ContestConfigurationRevision.fromJson,
    {SyncScope.contest},
  ),
  _Expected('ContestModelLink', ContestModelLink.fromJson, {SyncScope.contest}),
  _Expected('ContestParticipation', ContestParticipation.fromJson, {
    SyncScope.contest,
  }),
  _Expected('DelistRequest', DelistRequest.fromJson, {SyncScope.backendOnly}),
  _Expected('DisciplineConfigField', DisciplineConfigField.fromJson, {
    SyncScope.system,
  }),
  _Expected('DisciplineFormula', DisciplineFormula.fromJson, {
    SyncScope.system,
  }),
  _Expected('DisciplineProfile', DisciplineProfile.fromJson, {
    SyncScope.system,
  }),
  _Expected('DisciplineRule', DisciplineRule.fromJson, {SyncScope.system}),
  _Expected('DisciplineScoreField', DisciplineScoreField.fromJson, {
    SyncScope.system,
  }),
  _Expected('DisciplineValidation', DisciplineValidation.fromJson, {
    SyncScope.system,
  }),
  _Expected('FlightResult', FlightResult.fromJson, {SyncScope.derived}),
  _Expected('Installation', Installation.fromJson, {SyncScope.backendOnly}),
  _Expected('InstallationActivation', InstallationActivation.fromJson, {
    SyncScope.backendOnly,
  }),
  _Expected('Invitation', Invitation.fromJson, {SyncScope.issued}),
  _Expected('LandingTable', LandingTable.fromJson, {
    SyncScope.system,
    SyncScope.director,
  }),
  _Expected('MatrixAssignment', MatrixAssignment.fromJson, {SyncScope.contest}),
  _Expected('MatrixRevision', MatrixRevision.fromJson, {SyncScope.contest}),
  _Expected('ModelCatalog', ModelCatalog.fromJson, {SyncScope.director}),
  _Expected('MutationRecord', MutationRecord.fromJson, {
    SyncScope.contest,
    SyncScope.director,
  }),
  _Expected('OfficialScore', OfficialScore.fromJson, {SyncScope.contest}),
  _Expected('ParticipantAccountLink', ParticipantAccountLink.fromJson, {
    SyncScope.backendOnly,
  }),
  _Expected('ParticipantDirectoryEntry', ParticipantDirectoryEntry.fromJson, {
    SyncScope.backendOnly,
  }),
  _Expected('ParticipantProfile', ParticipantProfile.fromJson, {
    SyncScope.director,
  }),
  _Expected('ParticipationStanding', ParticipationStanding.fromJson, {
    SyncScope.derived,
  }),
  _Expected('PublicationIdentity', PublicationIdentity.fromJson, {
    SyncScope.backendOnly,
  }),
  _Expected('PublicationParticipant', PublicationParticipant.fromJson, {
    SyncScope.backendOnly,
  }),
  _Expected('PublicationProjection', PublicationProjection.fromJson, {
    SyncScope.backendOnly,
  }),
  _Expected('ReFlight', ReFlight.fromJson, {SyncScope.contest}),
  _Expected('ReFlightParticipant', ReFlightParticipant.fromJson, {
    SyncScope.contest,
  }),
  _Expected('ReviewRequest', ReviewRequest.fromJson, {SyncScope.contest}),
  _Expected('Role', Role.fromJson, {SyncScope.system, SyncScope.director}),
  _Expected('Round', Round.fromJson, {SyncScope.contest}),
  _Expected('RoundGroup', RoundGroup.fromJson, {SyncScope.contest}),
  _Expected('ScoreAttempt', ScoreAttempt.fromJson, {SyncScope.contest}),
  _Expected('ScorePlaceholder', ScorePlaceholder.fromJson, {SyncScope.contest}),
  _Expected('SyncCursor', SyncCursor.fromJson, {SyncScope.backendOnly}),
  _Expected('Team', Team.fromJson, {SyncScope.contest}),
  _Expected('TeamMembership', TeamMembership.fromJson, {SyncScope.contest}),
  _Expected('TeamStanding', TeamStanding.fromJson, {SyncScope.derived}),
  _Expected('Tombstone', Tombstone.fromJson, {
    SyncScope.contest,
    SyncScope.director,
  }),
];

void main() {
  final files = ExampleFiles.locate();
  final catalog = files.catalog();

  test('the table covers every catalog entity once, plus LandingResult', () {
    final named = [for (final e in _table) e.entity, 'LandingResult'];
    expect(named, hasLength(48));
    expect(named.toSet(), catalog.map((e) => e.entity).toSet());
  });

  group('sync scope of every example row', () {
    for (final expected in _table) {
      test(expected.entity, () {
        final entry = catalog.singleWhere((e) => e.entity == expected.entity);
        for (final row in files.rows(entry)) {
          final model = expected.decode(row.json);
          final scope = switch (model) {
            SyncScoped(:final syncScope) => syncScope,
            BackendOnly() => SyncScope.backendOnly,
            _ => throw StateError('{row} has no sync scope'),
          };
          expect(expected.scopes, contains(scope), reason: '$row');
        }
      });
    }

    test('LandingResult has no scope of its own', () {
      final entry = catalog.singleWhere((e) => e.entity == 'LandingResult');
      for (final row in files.rows(entry)) {
        final model = LandingResult.fromJson(row.json);
        expect(model, isNot(isA<SyncScoped>()));
        expect(model, isNot(isA<BackendOnly>()));
      }
    });
  });

  test('a synchronizable entity names its own type', () {
    for (final expected in _table) {
      final entry = catalog.singleWhere((e) => e.entity == expected.entity);
      final model = expected.decode(files.rows(entry).first.json);
      if (model is Synchronizable) {
        expect(model.entityType, expected.entity);
      }
    }
  });
}
