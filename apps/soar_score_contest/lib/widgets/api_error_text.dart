import '../services/api_failure.dart';

/// A short, user-facing description of [error] from an API call.
///
/// Uses the server's own message when it sent one, so rule failures such as
/// "participant has participations" reach the director unchanged.
String apiErrorText(Object error) => ApiFailure.of(error).message;
