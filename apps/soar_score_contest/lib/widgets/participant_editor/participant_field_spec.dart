import 'package:flutter/material.dart';

import '../../services/participants/participant_field.dart';

/// How one participant field behaves in the editor.
class ParticipantFieldSpec {
  const ParticipantFieldSpec(
    this.key, {
    this.autofill,
    this.capitalization = TextCapitalization.words,
    this.keyboard,
    this.autocorrect = true,
    this.help,
  });

  /// The key of the text field, for tests and journeys.
  final String key;
  final String? autofill;
  final TextCapitalization capitalization;
  final TextInputType? keyboard;
  final bool autocorrect;
  final String? help;

  static ParticipantFieldSpec of(ParticipantField field) => switch (field) {
    ParticipantField.firstName => const ParticipantFieldSpec(
      'first-name',
      autofill: AutofillHints.givenName,
    ),
    ParticipantField.lastName => const ParticipantFieldSpec(
      'last-name',
      autofill: AutofillHints.familyName,
    ),
    ParticipantField.email => const ParticipantFieldSpec(
      'email',
      autofill: AutofillHints.email,
      capitalization: TextCapitalization.none,
      keyboard: TextInputType.emailAddress,
      autocorrect: false,
    ),
    ParticipantField.club => const ParticipantFieldSpec(
      'club',
      autofill: AutofillHints.organizationName,
    ),
    ParticipantField.faiNumber => const ParticipantFieldSpec(
      'fai-number',
      capitalization: TextCapitalization.characters,
      autocorrect: false,
      help: "The pilot's FAI Sporting License ID.",
    ),
    ParticipantField.nationalOrgId => const ParticipantFieldSpec(
      'national-org-id',
      capitalization: TextCapitalization.characters,
      autocorrect: false,
      help:
          'Membership number with the national body, such as an AMA '
          'number. Leave blank if unknown.',
    ),
    ParticipantField.city => const ParticipantFieldSpec(
      'city',
      autofill: AutofillHints.addressCity,
    ),
    ParticipantField.state => const ParticipantFieldSpec(
      'state',
      autofill: AutofillHints.addressState,
    ),
    ParticipantField.country => const ParticipantFieldSpec(
      'country',
      autofill: AutofillHints.countryName,
      help: 'Pick from the list or type any country.',
    ),
  };
}

/// Fields that share a row on wide layouts.
const List<List<ParticipantField>> participantFieldRows = [
  [ParticipantField.firstName, ParticipantField.lastName],
  [ParticipantField.email],
  [ParticipantField.club],
  [ParticipantField.faiNumber, ParticipantField.nationalOrgId],
  [ParticipantField.city, ParticipantField.state],
  [ParticipantField.country],
];
