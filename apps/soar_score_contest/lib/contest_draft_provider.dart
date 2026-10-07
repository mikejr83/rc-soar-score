import 'package:flutter/widgets.dart';

import 'services/new_contest/contest_draft_store.dart';

/// Exposes the app-wide New Contest draft to the widget tree.
///
/// Mirrors `AppConnectivityInherited`: the store is created once by
/// `SoarScoreContestApp` so the draft outlives the wizard page and is kept
/// until the app is closed.
class ContestDraftInherited extends InheritedWidget {
  const ContestDraftInherited({
    super.key,
    required this.store,
    required super.child,
  });

  final ContestDraftStore store;

  @override
  bool updateShouldNotify(ContestDraftInherited oldWidget) =>
      store != oldWidget.store;
}

/// The app-wide [ContestDraftStore], or `null` when none is provided (tests
/// that pump pages bare).
ContestDraftStore? contestDraftStoreOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<ContestDraftInherited>()?.store;
