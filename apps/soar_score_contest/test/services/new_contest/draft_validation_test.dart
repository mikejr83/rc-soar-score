import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/draft_validation.dart';
import 'package:soar_score_contest/services/new_contest/participant_option.dart';
import 'package:soar_score_contest/services/new_contest/wizard_discipline.dart';

const _valid = ContestDraft(
  name: 'Gator Cup',
  venue: 'Hague Field',
  startDate: 'Nov 14, 2026',
  endDate: 'Nov 15, 2026',
);

void main() {
  group('details', () {
    test('a complete draft has no errors', () {
      expect(DraftValidation.details(_valid), isEmpty);
    });

    test('every required field is reported, in field order', () {
      expect(DraftValidation.details(const ContestDraft()).keys, [
        DetailsField.name,
        DetailsField.venue,
        DetailsField.startDate,
        DetailsField.endDate,
      ]);
    });

    test('blank text counts as missing', () {
      final errors = DraftValidation.details(_valid.copyWith(name: '   '));
      expect(errors[DetailsField.name], 'Enter a contest name.');
    });

    test('dates must be real dates in the shown format', () {
      final errors = DraftValidation.details(
        _valid.copyWith(startDate: '14/11/2026', endDate: 'Feb 30, 2026'),
      );
      expect(errors[DetailsField.startDate], 'Use a date like Nov 14, 2026.');
      expect(errors[DetailsField.endDate], 'Use a date like Nov 15, 2026.');
    });

    test('the end date may equal but not precede the start date', () {
      expect(
        DraftValidation.details(_valid.copyWith(endDate: 'Nov 14, 2026')),
        isEmpty,
      );
      expect(
        DraftValidation.details(
          _valid.copyWith(endDate: 'Nov 13, 2026'),
        )[DetailsField.endDate],
        'End date can’t be before the start date (Nov 14, 2026).',
      );
    });
  });

  test('a discipline is required', () {
    expect(DraftValidation.discipline(_valid), 'Choose a discipline.');
    expect(
      DraftValidation.discipline(
        _valid.copyWith(discipline: WizardDiscipline.ales),
      ),
      isNull,
    );
  });

  group('teamPilotCount', () {
    final teams = _valid.copyWith(options: {ParticipantOption.teams});

    test('is not needed without teams', () {
      expect(DraftValidation.teamPilotCount(_valid), isNull);
    });

    test('must be a whole number above 0 with teams', () {
      for (final bad in ['', '0', '-1', '2.5', 'three']) {
        expect(
          DraftValidation.teamPilotCount(teams.copyWith(teamPilotCount: bad)),
          'Enter a whole number above 0.',
          reason: bad,
        );
      }
      expect(
        DraftValidation.teamPilotCount(teams.copyWith(teamPilotCount: ' 3 ')),
        isNull,
      );
    });
  });
}
