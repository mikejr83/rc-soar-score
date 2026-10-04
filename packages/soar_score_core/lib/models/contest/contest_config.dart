import 'package:equatable/equatable.dart';

import 'core_options.dart';

/// The full resolved settings of a contest: `{ "core": {...}, "discipline":
/// {...} }`.
///
/// The maps are kept exactly as written so a stored configuration round-trips
/// unchanged. [coreOptions] reads and validates the core part against
/// `plan/data-model/contest-options.md`; the discipline part is defined by the
/// profile's configuration fields and validated where the profile is known.
class ContestConfig extends Equatable {
  ContestConfig({
    required Map<String, Object?> core,
    required Map<String, Object?> discipline,
  }) : core = Map.unmodifiable(core),
       discipline = Map.unmodifiable(discipline);

  factory ContestConfig.fromJson(Map<String, Object?> json) {
    final core = json['core'];
    final discipline = json['discipline'];
    if (core is! Map<String, Object?> || discipline is! Map<String, Object?>) {
      throw const FormatException(
        'expected {core: object, discipline: object}',
      );
    }
    return ContestConfig(core: core, discipline: discipline);
  }

  final Map<String, Object?> core;
  final Map<String, Object?> discipline;

  /// The core settings with platform defaults filled in, validated.
  ///
  /// Throws [ArgumentError] when a value or dependency is invalid.
  CoreOptions get coreOptions => CoreOptions.fromMap(core);

  Map<String, Object?> toJson() => {'core': core, 'discipline': discipline};

  @override
  List<Object?> get props => [core, discipline];
}
