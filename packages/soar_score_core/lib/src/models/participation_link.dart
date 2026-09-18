/// Represents a contest participation link.
///
/// A participation link joins one pilot profile to one contest. It is the
/// authoritative contest snapshot and contains contest-specific class, role,
/// team, start number, and privacy overrides.
class ParticipationLink {
  final String id;
  final String contestId;
  final String pilotId;
  final String? className;
  final String? roleRef;
  final String? teamRef;
  final int? startNumber;
  final String scoringUuid;
  final String privacyDisplay;
  final String participationStatus;

  ParticipationLink({
    required this.id,
    required this.contestId,
    required this.pilotId,
    this.className,
    this.roleRef,
    this.teamRef,
    this.startNumber,
    required this.scoringUuid,
    required this.privacyDisplay,
    required this.participationStatus,
  });
}