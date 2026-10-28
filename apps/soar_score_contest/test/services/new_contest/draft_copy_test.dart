import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/copy_mode.dart';
import 'package:soar_score_contest/services/new_contest/copy_source.dart';
import 'package:soar_score_contest/services/new_contest/draft_copy.dart';
import 'package:soar_score_contest/services/participants/participant_option.dart';
import 'package:soar_score_contest/services/new_contest/wizard_discipline.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/new_contest_test_support.dart';

final _pilots = [
  SourcePilot(
    profileId: Id.parse('019c0000-0000-7000-8000-000000000021'),
    name: 'Mike Gardner',
    classification: 'Open',
  ),
  SourcePilot(
    profileId: Id.parse('019c0000-0000-7000-8000-000000000022'),
    name: 'Sarah Albright',
  ),
];

CopySource _source({CoreOptions? options}) => CopySource(
  contest: sourceContest(),
  discipline: WizardDiscipline.f3j,
  options: options,
  pilots: _pilots,
);

void main() {
  test('configuration replaces the discipline, options and team count', () {
    const draft = ContestDraft(
      copyMode: CopyMode.configuration,
      discipline: WizardDiscipline.ales,
      options: {ParticipantOption.models},
    );
    final copied = draft.withSource(
      _source(
        options: CoreOptions(
          teamsEnabled: true,
          teamPilotCount: 2,
          rolesEnabled: true,
        ),
      ),
    );

    expect(copied.discipline, WizardDiscipline.f3j);
    expect(copied.options, {ParticipantOption.teams, ParticipantOption.roles});
    expect(copied.optionsFromSource, copied.options);
    expect(copied.teamPilotCount, '2');
    expect(copied.participants, isEmpty);
  });

  test('a source without a configuration keeps the draft options', () {
    const draft = ContestDraft(
      copyMode: CopyMode.configuration,
      options: {ParticipantOption.classes},
    );
    final copied = draft.withSource(_source());
    expect(copied.options, {ParticipantOption.classes});
    expect(copied.optionsFromSource, isEmpty);
  });

  test('all pilots copies every pilot with their class', () {
    final copied = const ContestDraft(copyMode: CopyMode.allPilots)
        .withSource(_source());
    expect(copied.participants.map((p) => p.name), [
      'Mike Gardner',
      'Sarah Albright',
    ]);
    expect(copied.participants.first.classification, 'Open');
    expect(copied.participants.every((p) => p.team.isEmpty), isTrue);
  });

  test('selected pilots copies only the chosen ones', () {
    final copied = const ContestDraft(copyMode: CopyMode.selectedPilots)
        .withSource(_source());
    final narrowed = copied
        .copyWith(selectedPilots: {_pilots.last.profileId.value})
        .withCopiedPilots();
    expect(narrowed.participants.map((p) => p.name), ['Sarah Albright']);
  });

  test('removing the source keeps copied values but drops the pilots', () {
    final copied = const ContestDraft(copyMode: CopyMode.allPilots)
        .withSource(_source(options: CoreOptions(classesEnabled: true)));
    final removed = copied.withoutSource();
    expect(removed.source, isNull);
    expect(removed.participants, isEmpty);
    expect(removed.discipline, WizardDiscipline.f3j);
    expect(removed.options, {ParticipantOption.classes});
    expect(removed.optionsFromSource, isEmpty);
  });
}
