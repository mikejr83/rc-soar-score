import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/participants/participant_field.dart';
import 'package:soar_score_contest/services/participants/participant_field_rules.dart';
import 'package:soar_score_contest/services/participants/participant_form_values.dart';

void main() {
  test('names and email are required, other fields are free', () {
    expect(
      participantFieldError(ParticipantField.firstName, ' '),
      'Enter a first name',
    );
    expect(
      participantFieldError(ParticipantField.lastName, ''),
      'Enter a last name',
    );
    expect(participantFieldError(ParticipantField.email, ''), 'Enter an email');
    expect(participantFieldError(ParticipantField.club, ''), isNull);
    expect(participantFieldError(ParticipantField.country, ''), isNull);
  });

  test('an email needs a name, an at sign and a dotted domain', () {
    const message = 'Enter an email like name@example.com';
    for (final bad in [
      'sam',
      'sam@',
      'sam@example',
      'sam@example.c',
      '@a.com',
    ]) {
      expect(participantFieldError(ParticipantField.email, bad), message);
    }
    expect(
      participantFieldError(ParticipantField.email, ' sam@example.com '),
      isNull,
    );
  });

  test('participantErrors lists fields in form order and honors skip', () {
    const values = ParticipantFormValues({
      ParticipantField.firstName: 'Sam',
      ParticipantField.email: 'sam@',
    });
    expect(participantErrors(values).keys, [
      ParticipantField.lastName,
      ParticipantField.email,
    ]);
    expect(participantErrors(values, skip: {ParticipantField.email}).keys, [
      ParticipantField.lastName,
    ]);
  });

  test('maskEmail keeps the first letter and the domain', () {
    expect(maskEmail('Alex.Moreau@example.com'), 'A***@example.com');
    expect(maskEmail('nope'), '***');
  });
}
