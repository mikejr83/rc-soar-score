/// The details a signed-in pilot offers contest directors (#652).
class DirectoryDetails {
  const DirectoryDetails({
    required this.firstName,
    required this.lastName,
    this.club,
    this.faiNumber,
    this.nationalOrgId,
    this.country,
    this.city,
    this.state,
    this.isListed = true,
    this.emailVisibleToDirectors = false,
  });

  final String firstName;
  final String lastName;
  final String? club;
  final String? faiNumber;
  final String? nationalOrgId;
  final String? country;

  /// Not edited on the details page, but carried through every save so that
  /// saving never clears what the API holds.
  final String? city;
  final String? state;

  /// "Let contest directors find me". Ticked until the pilot unticks it.
  final bool isListed;

  /// Whether a director may see the account's email. Private until the pilot
  /// says otherwise.
  final bool emailVisibleToDirectors;
}

/// What the details page starts from: the pilot's saved details, or their
/// account name with the defaults when they have none yet.
class OwnDirectory {
  const OwnDirectory({
    required this.hasEntry,
    required this.initial,
    required this.emailAvailable,
  });

  /// Whether the pilot has made an entry. False sends a first-time pilot to
  /// the details page.
  final bool hasEntry;
  final DirectoryDetails initial;
  final bool emailAvailable;
}
