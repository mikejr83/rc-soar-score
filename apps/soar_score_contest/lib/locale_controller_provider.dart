import 'package:flutter/widgets.dart';

import 'services/locale/locale_controller.dart';

/// Exposes the [LocaleController] to the widget tree; dependents rebuild when
/// the locale changes.
class LocaleControllerInherited extends InheritedNotifier<LocaleController> {
  const LocaleControllerInherited({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);
}

/// The app's [LocaleController], or `null` when none is provided (tests that
/// pump pages bare).
LocaleController? localeControllerOf(BuildContext context) => context
    .dependOnInheritedWidgetOfExactType<LocaleControllerInherited>()
    ?.notifier;
