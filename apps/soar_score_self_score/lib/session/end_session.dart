import 'package:soar_score_api/soar_score_api.dart';

import 'guest_session_store.dart';

/// Ends the guest session: asks the server to drop it and clear its cookie,
/// then forgets the session on this device. The local session is cleared
/// whether or not the server could be reached; a draft is kept, so opening
/// the link again restores it. Never throws.
///
/// Returns whether the server confirmed the end (or had nothing left to end:
/// a 401 means the session is already dead). With [clearOnFailure] false a
/// failed call leaves the device session in place, so the caller can say so
/// and try again with the cookie still known to exist.
Future<bool> endGuestSession(
  ApiClient? client,
  GuestSessionStore store, {
  bool clearOnFailure = true,
}) async {
  var ended = true;
  try {
    await client?.endGuestSession();
  } on ApiHttpError catch (error) {
    ended = error.statusCode == 401;
  } on Object {
    // Offline or already dead: the cookie then ends at its own expiry, and
    // the server refuses it once the invitation is replaced.
    ended = false;
  }
  if (ended || clearOnFailure) store.clear();
  return ended;
}
