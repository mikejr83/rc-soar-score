import 'package:flutter/widgets.dart';

import 'guest_session_store.dart';
import 'key_value_store.dart';
import 'score_draft_store.dart';

/// Provides the [GuestSessionStore] to the pages and the router.
class GuestSessionScope extends InheritedWidget {
  const GuestSessionScope({
    required this.store,
    required super.child,
    super.key,
  });

  final GuestSessionStore store;

  @override
  bool updateShouldNotify(GuestSessionScope oldWidget) =>
      store != oldWidget.store;
}

final _fallbackStore = MemoryGuestSessionStore();

extension GuestSessionStoreContext on BuildContext {
  /// The store the pages read the guest session from. With no scope above,
  /// a store that lasts as long as the page.
  GuestSessionStore get guestSessions =>
      getInheritedWidgetOfExactType<GuestSessionScope>()?.store ??
      _fallbackStore;
}

/// Provides the [ScoreDraftStore] to the score entry form.
class ScoreDraftScope extends InheritedWidget {
  const ScoreDraftScope({required this.store, required super.child, super.key});

  final ScoreDraftStore store;

  @override
  bool updateShouldNotify(ScoreDraftScope oldWidget) =>
      store != oldWidget.store;
}

extension ScoreDraftStoreContext on BuildContext {
  /// Where the entry form keeps its draft. With no scope above, nothing is
  /// kept: every call gets an empty store.
  ScoreDraftStore get scoreDrafts =>
      getInheritedWidgetOfExactType<ScoreDraftScope>()?.store ??
      ScoreDraftStore(MemoryKeyValueStore());
}
