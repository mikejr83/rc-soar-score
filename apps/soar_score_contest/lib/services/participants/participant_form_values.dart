import 'package:equatable/equatable.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'participant_field.dart';

/// The text of every editor field. Missing fields read as empty.
class ParticipantFormValues extends Equatable {
  const ParticipantFormValues([this._values = const {}]);

  factory ParticipantFormValues.fromProfile(ParticipantProfile profile) =>
      ParticipantFormValues({
        ParticipantField.firstName: profile.firstName,
        ParticipantField.lastName: profile.lastName,
        ParticipantField.email: profile.email ?? '',
        ParticipantField.club: profile.club ?? '',
        ParticipantField.faiNumber: profile.faiNumber ?? '',
        ParticipantField.nationalOrgId: profile.nationalOrgId ?? '',
        ParticipantField.city: profile.city ?? '',
        ParticipantField.state: profile.state ?? '',
        ParticipantField.country: profile.country ?? '',
      });

  final Map<ParticipantField, String> _values;

  String operator [](ParticipantField field) => _values[field] ?? '';

  ParticipantFormValues withField(ParticipantField field, String value) =>
      ParticipantFormValues({..._values, field: value});

  /// The trimmed value of [field], or null when it is blank.
  String? optional(ParticipantField field) {
    final text = this[field].trim();
    return text.isEmpty ? null : text;
  }

  /// "First Last", whichever parts are filled in.
  String get fullName => [
    this[ParticipantField.firstName].trim(),
    this[ParticipantField.lastName].trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  /// The fields whose trimmed text differs from [other].
  List<ParticipantField> differences(ParticipantFormValues other) => [
    for (final field in ParticipantField.values)
      if (this[field].trim() != other[field].trim()) field,
  ];

  @override
  List<Object?> get props => [
    for (final field in ParticipantField.values) this[field].trim(),
  ];
}
