/// What an accepted invitation link gives the browser: who the pilot is, which
/// contest, and the opaque token the API checks on every read and write.
class GuestSession {
  const GuestSession({
    required this.contestId,
    required this.contestName,
    required this.pilotId,
    required this.pilotName,
    required this.token,
  });

  factory GuestSession.fromJson(Map<String, Object?> json) => GuestSession(
    contestId: json['contestId']! as String,
    contestName: json['contestName']! as String,
    pilotId: json['pilotId']! as String,
    pilotName: json['pilotName']! as String,
    token: json['token']! as String,
  );

  final String contestId;
  final String contestName;
  final String pilotId;
  final String pilotName;

  /// Sent with every request. Never shown, and never put in an address.
  final String token;

  Map<String, Object?> toJson() => {
    'contestId': contestId,
    'contestName': contestName,
    'pilotId': pilotId,
    'pilotName': pilotName,
    'token': token,
  };
}
