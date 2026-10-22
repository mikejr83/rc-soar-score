import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/checklist/checklist_item.dart';
import 'package:soar_score_contest/services/workspace/checklist/setup_checklist.dart';
import 'package:soar_score_contest/services/workspace/publication_facts.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/configuration_fixtures.dart';
import '../../../support/matrix_test_support.dart';
import '../../../support/workspace_checklist_support.dart';

String _saved(DateTime at) => 'Oct 12, 14:05';

SetupChecklist _resolve(WorkspaceFacts facts) =>
    SetupChecklist.resolve(facts, formatSavedAt: _saved);

WorkspaceFacts _facts({
  LifecycleState state = LifecycleState.configuring,
  ScoringAccess scoringAccess = ScoringAccess.closed,
  AdminLock adminLock = AdminLock.unlocked,
  bool withConfiguration = true,
  Map<String, Object?> core = const {},
  Map<String, Object?> discipline = const {},
  bool numbered = false,
  CurrentMatrix? matrix,
  List<ContestParticipation>? participations,
  PublicationFacts publication = PublicationFacts.notPublished,
}) => WorkspaceFacts.derive(
  data: f5jWorkspaceData(
    state: state,
    scoringAccess: scoringAccess,
    adminLock: adminLock,
    withConfiguration: withConfiguration,
    core: core,
    discipline: discipline,
    numbered: numbered,
    matrix: matrix,
    participations: participations,
  ),
  landingTables: [landingTableView(f5jLandingTableId, 'F5J default')],
  publication: publication,
);

ChecklistItem _item(SetupChecklist list, ChecklistItemId id) =>
    [...list.required, ...list.optional].singleWhere((item) => item.id == id);

void main() {
  group('configuration row', () {
    test('is to do until a configuration is saved', () {
      final item = _item(
        _resolve(_facts(withConfiguration: false)),
        ChecklistItemId.configuration,
      );
      expect(item.status, ChecklistStatus.todo);
      expect(item.title, 'Configuration not saved');
      expect(item.target, ChecklistTarget.configuration);
    });

    test('is done with the revision and the time it was saved', () {
      final item = _item(_resolve(_facts()), ChecklistItemId.configuration);
      expect(item.status, ChecklistStatus.done);
      expect(item.detail, 'Revision 3 · saved Oct 12, 14:05');
    });

    test('is missing, with the problem, when the saved one is unusable', () {
      final item = _item(
        _resolve(_facts(core: const {'draw_mode': 'nonsense'})),
        ChecklistItemId.configuration,
      );
      expect(item.status, ChecklistStatus.missing);
      expect(item.detail, contains('not valid'));
    });
  });

  group('discipline row', () {
    test('is to do without a configuration', () {
      final item = _item(
        _resolve(_facts(withConfiguration: false)),
        ChecklistItemId.discipline,
      );
      expect(item.status, ChecklistStatus.todo);
    });

    test('names the discipline, the table and the house rules', () {
      final list = _resolve(_facts(discipline: {'working_time': 480}));
      final item = _item(list, ChecklistItemId.discipline);
      expect(item.status, ChecklistStatus.done);
      expect(item.detail, 'F5J · F5J default · 1 house rule');
    });

    test('says there are no house rules', () {
      final item = _item(_resolve(_facts()), ChecklistItemId.discipline);
      expect(item.detail, 'F5J · F5J default · no house rules');
    });

    test('still counts as chosen when the table name could not be read', () {
      final facts = WorkspaceFacts.derive(data: f5jWorkspaceData());
      final item = _item(_resolve(facts), ChecklistItemId.discipline);
      expect(item.status, ChecklistStatus.done);
      expect(item.detail, 'F5J · Landing table chosen · no house rules');
    });
  });

  group('pilots row', () {
    test('is done with the count and the participant setup', () {
      final item = _item(_resolve(_facts()), ChecklistItemId.pilots);
      expect(item.status, ChecklistStatus.done);
      expect(item.title, '4 scoring pilots');
      expect(item.detail, 'Teams off · classes off');
      expect(item.target, ChecklistTarget.participants);
    });

    test('is missing below two pilots', () {
      final one = _item(
        _resolve(_facts(participations: [matrixParticipations().first])),
        ChecklistItemId.pilots,
      );
      expect(one.status, ChecklistStatus.missing);
      expect(one.title, '1 scoring pilot');
      expect(one.detail, 'At least 2 are needed. Teams off · classes off');

      final none = _item(
        _resolve(_facts(participations: const [])),
        ChecklistItemId.pilots,
      );
      expect(none.title, 'No scoring pilots');
    });
  });

  group('matrix row', () {
    test('says it can be drawn once the items above are done', () {
      final item = _item(
        _resolve(_facts(withConfiguration: false)),
        ChecklistItemId.matrix,
      );
      expect(item.status, ChecklistStatus.todo);
      expect(item.detail, 'Can be drawn once the items above are done.');
    });

    test('says when it is ready to draw', () {
      final item = _item(_resolve(_facts()), ChecklistItemId.matrix);
      expect(item.status, ChecklistStatus.todo);
      expect(item.detail, 'Ready to draw on the Matrix page.');
    });

    test(
      'gives the blocker when everything above is done but it is locked',
      () {
        final item = _item(
          _resolve(_facts(adminLock: AdminLock.locked)),
          ChecklistItemId.matrix,
        );
        expect(item.status, ChecklistStatus.todo);
        expect(item.detail, contains('locked'));
      },
    );

    test('is done with rounds and group sizes', () {
      final item = _item(
        _resolve(_facts(matrix: drawnMatrix())),
        ChecklistItemId.matrix,
      );
      expect(item.status, ChecklistStatus.done);
      expect(item.title, 'Matrix drawn');
      expect(item.detail, endsWith('2 rounds · 2 groups of 2'));
      expect(item.detail, startsWith('Revision '));
    });

    test('is a check when the configuration changed since the draw', () {
      final item = _item(
        _resolve(
          _facts(matrix: drawnMatrix(config: const {'team_protection': true})),
        ),
        ChecklistItemId.matrix,
      );
      expect(item.status, ChecklistStatus.check);
      expect(item.title, 'Matrix doesn’t match the configuration');
      expect(
        item.detail,
        contains('Team protection is now Off (drawn with On).'),
      );
      expect(item.detail, contains('2 rounds'));
    });
  });

  group('optional rows', () {
    test('participant numbers are hidden when the option is off', () {
      final list = _resolve(_facts());
      expect(
        list.optional.map((item) => item.id),
        isNot(contains(ChecklistItemId.participantNumbers)),
      );
    });

    test('participant numbers are to do before the draw', () {
      final list = _resolve(
        _facts(core: const {'participant_numbers_enabled': true}),
      );
      final item = _item(list, ChecklistItemId.participantNumbers);
      expect(item.status, ChecklistStatus.todo);
    });

    test('participant numbers are done once handed out, drift or not', () {
      final item = _item(
        _resolve(
          _facts(
            core: const {'participant_numbers_enabled': true},
            numbered: true,
            matrix: drawnMatrix(config: const {'team_protection': true}),
          ),
        ),
        ChecklistItemId.participantNumbers,
      );
      expect(item.status, ChecklistStatus.done);
      expect(item.detail, '1–4, assigned at the draw.');
    });

    test('publication is not published, published, or unknown', () {
      expect(
        _item(_resolve(_facts()), ChecklistItemId.publication).title,
        'Not published',
      );
      final published = _item(
        _resolve(
          _facts(
            publication: const PublicationFacts(
              isPublished: true,
              visibility: PublicationVisibility.public,
            ),
          ),
        ),
        ChecklistItemId.publication,
      );
      expect(published.status, ChecklistStatus.done);
      expect(published.detail, 'Public on the public site.');
      final unknown = _item(
        _resolve(_facts(publication: PublicationFacts.unknown)),
        ChecklistItemId.publication,
      );
      expect(unknown.status, ChecklistStatus.unknown);
      expect(unknown.title, 'Publication status unavailable');
      expect(unknown.target, ChecklistTarget.publicationControl);
    });

    test('unsupported publishing is not a task, not unknown', () {
      final unsupported = _item(
        _resolve(_facts(publication: PublicationFacts.unsupported)),
        ChecklistItemId.publication,
      );
      expect(unsupported.status, ChecklistStatus.done);
      expect(unsupported.title, 'Publication not supported');
      expect(unsupported.detail, 'This server does not publish contests.');
      expect(unsupported.target, ChecklistTarget.publicationControl);
    });

    test('scoring access is closed or open', () {
      final closed = _item(_resolve(_facts()), ChecklistItemId.scoringAccess);
      expect(closed.status, ChecklistStatus.todo);
      expect(closed.detail, contains('Open it when pilots should enter'));
      final open = _item(
        _resolve(_facts(scoringAccess: ScoringAccess.open)),
        ChecklistItemId.scoringAccess,
      );
      expect(open.status, ChecklistStatus.done);
      expect(open.target, ChecklistTarget.scoringControl);
    });
  });

  group('summary', () {
    test('counts the required items that are done', () {
      final list = _resolve(_facts(participations: const []));
      expect(list.required, hasLength(4));
      expect(list.summary, '2 of 4 required items done');
      expect(list.requiredComplete, isFalse);
    });

    test('is complete when all four are done', () {
      final list = _resolve(_facts(matrix: drawnMatrix()));
      expect(list.summary, '4 of 4 required items done');
      expect(list.requiredComplete, isTrue);
    });

    test('a status is spoken, not only shown', () {
      final item = _item(_resolve(_facts()), ChecklistItemId.pilots);
      expect(
        item.semanticLabel,
        '4 scoring pilots. Done. Teams off · classes off',
      );
    });
  });
}
