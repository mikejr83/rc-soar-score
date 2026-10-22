import 'package:flutter/material.dart';

/// A named status value shown as an icon plus text, spoken as "Field: value".
///
/// Status is never colour alone: the icon shape and the word carry it, and
/// the semantics label names the field so a screen reader does not read a
/// bare "Running". The visible [child] (a chip, say) is excluded from the
/// semantics tree so it is not read twice.
class StatusLabel extends StatelessWidget {
  const StatusLabel({
    super.key,
    required this.field,
    required this.value,
    required this.child,
  });

  /// What the value is the value of, such as `Lifecycle`.
  final String field;

  /// The value in words, such as `Running`.
  final String value;

  /// The visible chip or text that shows [value] with its icon.
  final Widget child;

  /// The text a screen reader speaks.
  String get semanticsLabel => '$field: $value';

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semanticsLabel,
    child: ExcludeSemantics(child: child),
  );
}
