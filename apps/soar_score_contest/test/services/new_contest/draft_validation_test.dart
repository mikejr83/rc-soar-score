import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft.dart';
import 'package:soar_score_contest/services/new_contest/draft_validation.dart';
import 'package:soar_score_contest/services/participants/participant_option.dart';
import 'package:soar_score_contest/services/new_contest/wizard_discipline.dart';

const _valid = ContestDraft(
  name: 'Gator Cup',
  venue: 'Hague Field',
  startDate: 'Nov 14, 2026',
  endDate: 'Nov 15, 2026',
);

final _l10n = AppLocalizationsEn();

void main() {
  group('details', () {
    test('a complete draft has no errors', () {
      expect(DraftValidation.details(_valid, _l10n), isEmpty);
    });

    test('every required field is reported, in field order', () {
      expect(DraftValidation.details(const ContestDraft(), _l10n).keys, [
        DetailsField.name,
        DetailsField.venue,
        DetailsField.startDate,
        DetailsField.endDate,
      ]);
    });

    test('blank text counts as missing', () {
      final errors = DraftValidation.details(
        _valid.copyWith(name: '   '),
        _l10n,
      );
      expect(errors[DetailsField.name], _l10n.wizardValidationEnterName);
    });

    test('dates must be real dates in the shown format', () {
      final errors = DraftValidation.details(
        _valid.copyWith(startDate: '14/11/2026', endDate: 'Feb 30, 2026'),
        _l10n,
      );
      expect(
        errors[DetailsField.startDate],
        _l10n.wizardValidationStartDateFormat,
      );
      expect(errors[DetailsField.endDate], _l10n.wizardValidationEndDateFormat);
    });

    test('the end date may equal but not precede the start date', () {
      expect(
        DraftValidation.details(
          _valid.copyWith(endDate: 'Nov 14, 2026'),
          _l10n,
        ),
        isEmpty,
      );
      expect(
        DraftValidation.details(
          _valid.copyWith(endDate: 'Nov 13, 2026'),
          _l10n,
        )[DetailsField.endDate],
        _l10n.wizardValidationEndDateBeforeStart('Nov 14, 2026'),
      );
    });
  });

  test('a discipline is required', () {
    expect(
      DraftValidation.discipline(_valid, _l10n),
      _l10n.wizardValidationChooseDiscipline,
    );
    expect(
      DraftValidation.discipline(
        _valid.copyWith(discipline: WizardDiscipline.ales),
        _l10n,
      ),
      isNull,
    );
  });

  group('teamPilotCount', () {
    final teams = _valid.copyWith(options: {ParticipantOption.teams});

    test('is not needed without teams', () {
      expect(DraftValidation.teamPilotCount(_valid, _l10n), isNull);
    });

    test('must be a whole number above 0 with teams', () {
      for (final bad in ['', '0', '-1', '2.5', 'three']) {
        expect(
          DraftValidation.teamPilotCount(
            teams.copyWith(teamPilotCount: bad),
            _l10n,
          ),
          _l10n.wizardValidationWholeNumber,
          reason: bad,
        );
      }
      expect(
        DraftValidation.teamPilotCount(
          teams.copyWith(teamPilotCount: ' 3 '),
          _l10n,
        ),
        isNull,
      );
    });
  });
}
