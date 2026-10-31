import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/draft_participant.dart';
import 'package:soar_score_contest/services/new_contest/draft_validation.dart';
import 'package:soar_score_contest/services/participants/participant_option.dart';
import 'package:soar_score_contest/services/new_contest/participant_rules.dart';
import 'package:soar_score_contest/services/participants/participant_row.dart';
import 'package:soar_score_core/soar_score_core.dart';

DraftParticipant _p(
  int n, {
  String classification = '',
  String team = '',
  bool pilot = true,
}) {
  final base = DraftParticipant(
    profileId: Id.parse('019c0000-0000-7000-8000-0000000000$n'),
    name: 'Pilot $n',
  );
  return base.copyWith(
    role: pilot ? null : SystemRoles.helper,
    classification: classification,
    team: team,
  );
}

ContestDraft _draft(
  List<DraftParticipant> participants, {
  Set<ParticipantOption> options = const {},
}) => ContestDraft(options: options, participants: participants);

void main() {
  test('title case and initials', () {
    expect(titleCase('  open  CLASS '), 'Open  Class');
    expect(initials('Flying Gators'), 'FG');
    expect(initials('Tidewater Thermals Club'), 'TT');
  });

  test('without roles everyone scores; with roles only pilots do', () {
    final draft = _draft([_p(11), _p(12, pilot: false)]);
    expect(draft.scoringCount, 2);
    expect(draft.copyWith(options: {ParticipantOption.roles}).scoringCount, 1);
  });

  test('scoring pilots need a class when classes are on', () {
    final draft = _draft(
      [_p(11, classification: 'Open'), _p(12), _p(13, pilot: false)],
      options: {
        ParticipantOption.classes,
        ParticipantOption.models,
        ParticipantOption.roles,
      },
    );
    expect(draft.issuesOf(draft.participants[0]), isEmpty);
    // A missing model is a notice only; it never holds a pilot back.
    expect(draft.issuesOf(draft.participants[1]), [
      ParticipantIssue.classification,
    ]);
    // Non-flying roles are not scored, so they need neither.
    expect(draft.issuesOf(draft.participants[2]), isEmpty);
    expect(DraftValidation.participants(draft), isFalse);
  });

  test('a pilot without a model is ready; models never block', () {
    final draft = _draft([_p(11), _p(12)], options: {ParticipantOption.models});
    expect(draft.participants.every((p) => p.models.isEmpty), isTrue);
    expect(draft.participantsNeedingFixes, isEmpty);
    expect(DraftValidation.participants(draft), isTrue);
  });

  test('a team is optional', () {
    final draft = _draft([_p(11), _p(12)], options: {ParticipantOption.teams});
    expect(draft.participantsNeedingFixes, isEmpty);
    expect(DraftValidation.participants(draft), isTrue);
  });

  test('at least two scoring pilots are needed', () {
    expect(DraftValidation.participants(_draft([_p(11)])), isFalse);
    expect(DraftValidation.participants(_draft([_p(11), _p(12)])), isTrue);
  });

  test('teams group ignoring case and keep their first spelling', () {
    final draft = _draft([
      _p(11, team: 'Flying Gators'),
      _p(12, team: 'flying gators '),
      _p(13, team: 'Lake Wings'),
      _p(14),
    ]);
    expect(draft.teams.map((team) => '${team.name} ${team.count}'), [
      'Flying Gators 2',
      'Lake Wings 1',
    ]);
    expect(draft.normalizeTeam('LAKE wings'), 'Lake Wings');
    expect(draft.normalizeTeam('silent wings rc'), 'Silent Wings Rc');
    expect(draft.normalizeTeam('  '), '');
  });

  test('class suggestions are title-cased and unique', () {
    final draft = _draft([
      _p(11, classification: 'open'),
      _p(12, classification: 'Open'),
      _p(13, classification: 'sportsman'),
    ]);
    expect(draft.classes, ['Open', 'Sportsman']);
  });
}
