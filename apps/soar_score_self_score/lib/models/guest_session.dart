/// What an accepted invitation link gives the browser: who the pilot is, which
/// contest, and the opaque token the API checks on every read and write.
class GuestSession {
  const GuestSession({
    required this.contestId,
    required this.contestName,
    required this.pilotId,
    required this.pilotName,
    this.token,
    this.role = 'pilot',
    this.expiresAt,
  });

  factory GuestSession.fromJson(Map<String, Object?> json) => GuestSession(
    contestId: json['contestId']! as String,
    contestName: json['contestName']! as String,
    pilotId: json['pilotId']! as String,
    pilotName: json['pilotName']! as String,
    token: json['token'] as String?,
    role: json['role'] as String? ?? 'pilot',
    expiresAt: switch (json['expiresAt']) {
      final String text => DateTime.tryParse(text),
      _ => null,
    },
  );

  final String contestId;
  final String contestName;
  final String pilotId;
  final String pilotName;

  /// Sent as a bearer token when the server gave one in the body (native
  /// clients and tests). Null on the web, where the session lives in an
  /// HttpOnly cookie that the page cannot read. Never shown, and never put in
  /// an address.
  final String? token;

  /// What the link makes the person: `pilot` is the only role in the first
  /// field release. The server decides what the role may see.
  final String role;

  /// When the server stops accepting [token]. Null when it did not say.
  final DateTime? expiresAt;

  /// Whether the server would already refuse [token] at [now].
  bool isExpired(DateTime now) =>
      expiresAt != null && !now.isBefore(expiresAt!);

  Map<String, Object?> toJson() => {
    'contestId': contestId,
    'contestName': contestName,
    'pilotId': pilotId,
    'pilotName': pilotName,
    if (token != null) 'token': token,
    'role': role,
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
  };
}
