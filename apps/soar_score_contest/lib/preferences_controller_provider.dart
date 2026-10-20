import 'package:flutter/widgets.dart';

import 'services/preferences/preferences_controller.dart';

/// Exposes the [PreferencesController] to the widget tree; dependents rebuild
/// when the time zone or locale changes.
class PreferencesControllerInherited
    extends InheritedNotifier<PreferencesController> {
  const PreferencesControllerInherited({
    super.key,
    required PreferencesController controller,
    required super.child,
  }) : super(notifier: controller);
}

/// The app's [PreferencesController], or `null` when none is provided (tests that
/// pump pages bare).
PreferencesController? preferencesOf(BuildContext context) => context
    .dependOnInheritedWidgetOfExactType<PreferencesControllerInherited>()
    ?.notifier;
