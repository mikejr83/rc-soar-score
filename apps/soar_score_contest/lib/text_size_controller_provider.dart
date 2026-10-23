import 'package:flutter/widgets.dart';

import 'services/text_size/text_size_controller.dart';

/// Exposes the [TextSizeController] to the widget tree; dependents rebuild
/// when the text size changes.
class TextSizeControllerInherited
    extends InheritedNotifier<TextSizeController> {
  const TextSizeControllerInherited({
    super.key,
    required TextSizeController controller,
    required super.child,
  }) : super(notifier: controller);
}

/// The app's [TextSizeController], or `null` when none is provided (tests
/// that pump pages bare).
TextSizeController? textSizeControllerOf(BuildContext context) => context
    .dependOnInheritedWidgetOfExactType<TextSizeControllerInherited>()
    ?.notifier;
