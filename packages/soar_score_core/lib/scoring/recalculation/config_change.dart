import 'package:equatable/equatable.dart';

import 'option_group.dart';

/// One setting whose value differs between two configuration revisions.
class ChangedOption extends Equatable {
  const ChangedOption(this.key, this.group);

  /// The core option key, a `discipline.<field>` key, or `landing_table`.
  final String key;
  final OptionGroup group;

  @override
  List<Object?> get props => [key, group];
}

/// A change the contest's lifecycle state does not allow.
class RejectedChange extends Equatable {
  const RejectedChange(this.option, this.reason);

  final ChangedOption option;
  final String reason;

  @override
  List<Object?> get props => [option, reason];
}

/// The difference between two configuration revisions and what it means.
class ConfigChange extends Equatable {
  ConfigChange({
    required List<ChangedOption> changes,
    required List<RejectedChange> rejected,
    required this.offerRedraw,
  }) : changes = List.unmodifiable(changes),
       rejected = List.unmodifiable(rejected);

  final List<ChangedOption> changes;

  /// Changes the lifecycle state forbids. When any exists the change as a
  /// whole must not be saved.
  final List<RejectedChange> rejected;

  /// True when a structural option changed after the draw and before any
  /// score: the director is warned and offered a redraw of unscored rounds.
  final bool offerRedraw;

  bool get isAllowed => rejected.isEmpty;

  /// Whether any stored result becomes stale. The scoring-rule groups and the
  /// recalculating group do; structural and presentation changes do not.
  bool get requiresRecalculation => changes.any(
    (c) =>
        c.group == OptionGroup.recalculating ||
        c.group == OptionGroup.scoringRules,
  );

  @override
  List<Object?> get props => [changes, rejected, offerRedraw];
}
