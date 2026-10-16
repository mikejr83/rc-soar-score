import 'package:flutter/widgets.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

/// Exposes the [LocalUiStore] (theme, hidden panels, drafts) to the widget
/// tree. Mirrors `ContestDraftInherited`.
class LocalUiStoreInherited extends InheritedWidget {
  const LocalUiStoreInherited({
    super.key,
    required this.store,
    required super.child,
  });

  final LocalUiStore store;

  @override
  bool updateShouldNotify(LocalUiStoreInherited oldWidget) =>
      store != oldWidget.store;
}

/// The app's [LocalUiStore], or `null` when none is provided (tests that pump
/// pages bare).
LocalUiStore? localUiStoreOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<LocalUiStoreInherited>()?.store;
