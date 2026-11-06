import 'dart:convert';

import '../models/guest_session.dart';
import 'key_value_store.dart';

/// Keeps the guest session so a pilot can close the browser and come back.
/// Kept thin so a native app can swap in secure storage later.
abstract interface class GuestSessionStore {
  GuestSession? read();

  void write(GuestSession session);

  void clear();
}

/// Holds the session for the life of the page. Used in tests and when the
/// browser refuses to store anything.
class MemoryGuestSessionStore implements GuestSessionStore {
  GuestSession? _session;

  @override
  GuestSession? read() {
    final session = _session;
    if (session != null && session.isExpired(DateTime.now())) _session = null;
    return _session;
  }

  @override
  void write(GuestSession session) => _session = session;

  @override
  void clear() => _session = null;
}

/// Reads and writes the session as JSON in a string slot. [StringSlot] is the
/// browser's local storage on the web.
class StringSlotGuestSessionStore implements GuestSessionStore {
  StringSlotGuestSessionStore(this._slot, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final StringSlot _slot;
  final DateTime Function() _now;

  @override
  GuestSession? read() {
    try {
      final raw = _slot.read();
      if (raw == null) return null;
      final json = (jsonDecode(raw) as Map).cast<String, Object?>();
      if (json['token'] != null) {
        // Written before the session moved into a cookie: it holds a
        // credential. Drop it, and the pilot opens their link again.
        _slot.clear();
        return null;
      }
      final session = GuestSession.fromJson(json);
      if (session.isExpired(_now())) {
        // The server would refuse it: do not route from it.
        _slot.clear();
        return null;
      }
      return session;
    } on Object {
      // A damaged or blocked slot counts as no session.
      return null;
    }
  }

  @override
  void write(GuestSession session) {
    try {
      // Only display data is kept in browser storage, never a credential.
      final stored = session.toJson()..remove('token');
      _slot.write(jsonEncode(stored));
    } on Object {
      // Storage can be blocked, for example in a private window. The session
      // still works until the page closes.
    }
  }

  @override
  void clear() {
    try {
      _slot.clear();
    } on Object {
      // See write.
    }
  }
}

/// One string kept somewhere durable.
abstract interface class StringSlot {
  String? read();

  void write(String value);

  void clear();
}

/// A [StringSlot] that is one key of a [KeyValueStore].
class KeyValueSlot implements StringSlot {
  const KeyValueSlot(this._store, this._key);

  final KeyValueStore _store;
  final String _key;

  @override
  String? read() => _store.read(_key);

  @override
  void write(String value) => _store.write(_key, value);

  @override
  void clear() => _store.remove(_key);
}
