/// The fields of a reusable participant profile the editor shows.
enum ParticipantField {
  firstName('First name'),
  lastName('Last name'),
  email('Email'),
  club('Club'),
  faiNumber('FAI number'),
  nationalOrgId('National organization ID'),
  city('City'),
  state('State/province'),
  country('Country');

  const ParticipantField(this.label);

  final String label;

  /// Fields the profile cannot be saved without.
  bool get required => this == firstName || this == lastName || this == email;
}

/// A group of fields shown together in the editor.
enum ParticipantSection {
  contact('Name and contact', [
    ParticipantField.firstName,
    ParticipantField.lastName,
    ParticipantField.email,
  ]),
  identification('Identification', [
    ParticipantField.club,
    ParticipantField.faiNumber,
    ParticipantField.nationalOrgId,
  ]),
  location('Location', [
    ParticipantField.city,
    ParticipantField.state,
    ParticipantField.country,
  ]);

  const ParticipantSection(this.title, this.fields);

  final String title;
  final List<ParticipantField> fields;
}
