import 'package:web/web.dart' as web;

import 'guest_session_store.dart';

const _key = 'soar_score_self_score.guest_session';

class _LocalStorageSlot implements StringSlot {
  @override
  String? read() => web.window.localStorage.getItem(_key);

  @override
  void write(String value) => web.window.localStorage.setItem(_key, value);

  @override
  void clear() => web.window.localStorage.removeItem(_key);
}

/// The guest session lives in the browser's local storage.
GuestSessionStore openGuestSessionStore() =>
    StringSlotGuestSessionStore(_LocalStorageSlot());
