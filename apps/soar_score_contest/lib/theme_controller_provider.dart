import 'package:flutter/widgets.dart';

import 'services/theme/theme_controller.dart';

/// Exposes the [ThemeController] to the widget tree; dependents rebuild when
/// the theme mode changes.
class ThemeControllerInherited extends InheritedNotifier<ThemeController> {
  const ThemeControllerInherited({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);
}

/// The app's [ThemeController], or `null` when none is provided (tests that
/// pump pages bare).
ThemeController? themeControllerOf(BuildContext context) => context
    .dependOnInheritedWidgetOfExactType<ThemeControllerInherited>()
    ?.notifier;
