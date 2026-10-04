import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'landing_result.g.dart';

/// A selectable entry in a landing table: key, label and points.
///
/// Immutable and created with its table. It has no owner of its own, so it
/// travels in the same stream as its [LandingTable] and is not [SyncScoped].
/// See `plan/data-model/entities/landing_result.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
class LandingResult extends Equatable {
  LandingResult({
    required this.id,
    required this.landingTableId,
    required String entryKey,
    required String displayValue,
    required this.pointValue,
    required this.ordinalPosition,
  }) : entryKey = requireNotBlank(entryKey, 'entryKey'),
       displayValue = requireNotBlank(displayValue, 'displayValue') {
    requireNonNegative(pointValue, 'pointValue');
    requireNonNegative(ordinalPosition, 'ordinalPosition');
  }

  factory LandingResult.fromJson(Map<String, Object?> json) =>
      _$LandingResultFromJson(json);

  /// The value a score stores.
  final Id id;

  final Id landingTableId;

  /// What the scorer selects, for example `within_1m`; unique in the table.
  final String entryKey;

  /// Label shown to the user.
  final String displayValue;

  /// Landing points awarded; never negative. The system takes points from
  /// here, never from the label.
  final int pointValue;

  /// Position in the selection list; unique in the table.
  final int ordinalPosition;

  Map<String, Object?> toJson() => _$LandingResultToJson(this);

  @override
  List<Object?> get props => [
    id,
    landingTableId,
    entryKey,
    displayValue,
    pointValue,
    ordinalPosition,
  ];
}
