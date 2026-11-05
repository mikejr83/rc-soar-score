import 'guest_session_store.dart';

/// No browser storage off the web; the app is web-only, so this is for tests.
GuestSessionStore openGuestSessionStore() => MemoryGuestSessionStore();
