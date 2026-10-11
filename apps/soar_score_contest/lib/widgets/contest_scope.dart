import 'package:flutter/widgets.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The selected contest as the shell loaded it, plus a way to load it again.
///
/// The shell status panel reads the same contest, so a page that changes the
/// contest calls [reload] and the panel follows without a page reload.
class ContestScope extends InheritedWidget {
  const ContestScope({
    super.key,
    required this.contest,
    required this.reload,
    required super.child,
  });

  /// The loaded contest, or `null` while loading or when none is selected.
  final Contest? contest;

  /// Loads the contest again and rebuilds everything that reads the scope.
  final VoidCallback reload;

  /// The nearest scope, or `null` outside a shell.
  static ContestScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ContestScope>();

  @override
  bool updateShouldNotify(ContestScope oldWidget) =>
      contest != oldWidget.contest;
}
