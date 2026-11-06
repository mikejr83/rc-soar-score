/// What an accepted invitation link gives the browser: who the pilot is, which
/// contest, and the opaque token the API checks on every read and write.
class GuestSession {
  const GuestSession({
    required this.contestId,
    required this.contestName,
    required this.pilotId,
    required this.pilotName,
    required this.token,
    required this.expiresAt,
    this.pilotNumber,
    this.role = 'pilot',
  });

  factory GuestSession.fromJson(Map<String, Object?> json) => GuestSession(
    contestId: json['contestId']! as String,
    contestName: json['contestName']! as String,
    pilotId: json['pilotId']! as String,
    pilotName: json['pilotName']! as String,
    token: json['token']! as String,
    pilotNumber: json['pilotNumber'] as int?,
    role: json['role'] as String? ?? 'pilot',
    // A stored session with no readable expiry is refused, not kept for ever.
    expiresAt: DateTime.parse(json['expiresAt']! as String),
  );

  final String contestId;
  final String contestName;
  final String pilotId;
  final String pilotName;

  /// Null when the contest gives pilots no number.
  final int? pilotNumber;

  /// Sent with every request. Never shown, and never put in an address.
  final String token;

  /// What the link makes the person: `pilot` is the only role in the first
  /// field release. The server decides what the role may see.
  final String role;

  /// When the server stops accepting the session. Always known: the server
  /// sends it with the session, and a stored one without it is not used.
  final DateTime expiresAt;

  /// Whether the server would already refuse [token] at [now].
  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  Map<String, Object?> toJson() => {
    'contestId': contestId,
    'contestName': contestName,
    'pilotId': pilotId,
    'pilotName': pilotName,
    'pilotNumber': ?pilotNumber,
    'token': token,
    'role': role,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };
}
