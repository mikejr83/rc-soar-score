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
