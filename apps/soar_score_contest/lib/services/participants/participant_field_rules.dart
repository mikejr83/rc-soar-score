import 'participant_field.dart';
import 'participant_form_values.dart';

final RegExp _emailShape = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// What is wrong with [value] for [field], or null when it is fine.
///
/// The wording tells the director what to enter, not just that it failed.
String? participantFieldError(ParticipantField field, String value) {
  final text = value.trim();
  switch (field) {
    case ParticipantField.firstName:
      return text.isEmpty ? 'Enter a first name' : null;
    case ParticipantField.lastName:
      return text.isEmpty ? 'Enter a last name' : null;
    case ParticipantField.email:
      if (text.isEmpty) {
        return 'Enter an email';
      }
      return _emailShape.hasMatch(text)
          ? null
          : 'Enter an email like name@example.com';
    default:
      return null;
  }
}

/// The fields of [values] that cannot be saved, in form order, with their
/// messages. [skip] lists fields the director cannot change (read-only).
Map<ParticipantField, String> participantErrors(
  ParticipantFormValues values, {
  Set<ParticipantField> skip = const {},
}) {
  final errors = <ParticipantField, String>{};
  for (final field in ParticipantField.values) {
    final message = skip.contains(field)
        ? null
        : participantFieldError(field, values[field]);
    if (message != null) {
      errors[field] = message;
    }
  }
  return errors;
}

/// The address with all but its first character before the `@` hidden,
/// for showing another profile's email without revealing it.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at < 1) {
    return '***';
  }
  return '${email[0]}***${email.substring(at)}';
}
