/// Represents a pilot (participant profile).
///
/// A pilot is a reusable participant profile with identity and contact data.
/// Pilot profiles can be shared across contests through participation links.
/// Contest-specific data (class, role, team, start number) belongs on the
/// participation link, not the profile itself.
class Pilot {
  final String id;
  final String firstName;
  final String lastName;
  final String? club;
  final String? faiNumber;
  final String? nationalOrgId;
  final String? city;
  final String? stateProvince;
  final String? country;
  final String? email;

  Pilot({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.club,
    this.faiNumber,
    this.nationalOrgId,
    this.city,
    this.stateProvince,
    this.country,
    this.email,
  });
}