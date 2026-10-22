import 'participant_field.dart';
import 'participant_form_values.dart';

/// The fields "Save and add another" carries into the next form: the club
/// and the location, which pilots entered in a row usually share.
const List<ParticipantField> keptParticipantFields = [
  ParticipantField.club,
  ParticipantField.city,
  ParticipantField.state,
  ParticipantField.country,
];

/// A fresh form holding only the kept fields of [saved].
ParticipantFormValues keptValuesOf(ParticipantFormValues saved) =>
    ParticipantFormValues({
      for (final field in keptParticipantFields) field: saved[field],
    });

/// Whether [values] has anything worth announcing as kept.
bool hasKeptValues(ParticipantFormValues values) =>
    keptParticipantFields.any((field) => values[field].trim().isNotEmpty);
