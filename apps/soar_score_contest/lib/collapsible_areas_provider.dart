import 'package:flutter/widgets.dart';

import 'services/collapsible_areas/collapsible_areas_controller.dart';

/// Exposes the [CollapsibleAreasController] to the widget tree; dependents
/// rebuild when a choice changes.
class CollapsibleAreasInherited
    extends InheritedNotifier<CollapsibleAreasController> {
  const CollapsibleAreasInherited({
    super.key,
    required CollapsibleAreasController controller,
    required super.child,
  }) : super(notifier: controller);
}

/// The app's [CollapsibleAreasController], or `null` when none is provided
/// (tests that pump pages bare).
CollapsibleAreasController? collapsibleAreasOf(BuildContext context) => context
    .dependOnInheritedWidgetOfExactType<CollapsibleAreasInherited>()
    ?.notifier;
