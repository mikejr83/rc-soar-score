import 'package:soar_score_api/soar_score_api.dart';

import 'guest_session_store.dart';

/// Ends the guest session: asks the server to drop it and clear its cookie,
/// then forgets the session on this device. The local session is cleared
/// whether or not the server could be reached; a draft is kept, so opening
/// the link again restores it. Never throws.
Future<void> endGuestSession(ApiClient? client, GuestSessionStore store) async {
  try {
    await client?.endGuestSession();
  } on Object {
    // Offline or already dead: the cookie then ends at its own expiry, and
    // the server refuses it once the invitation is replaced.
  } finally {
    store.clear();
  }
}

/// Ends a session that acts as the account, for sign-out. Unlike
/// [endGuestSession] it does not hide a failure: the server must confirm the
/// cookie is cleared, and on failure the local session is kept so the pilot can
/// try again. Throws when the request fails.
Future<void> endAccountSession(
  ApiClient? client,
  GuestSessionStore store,
) async {
  await client?.endGuestSession();
  store.clear();
}
