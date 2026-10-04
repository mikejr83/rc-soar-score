import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/formula_type.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'discipline_formula.g.dart';

/// A score or penalty formula of a discipline's calculation chain.
///
/// System data. See `plan/data-model/entities/discipline_formula.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class DisciplineFormula extends Equatable implements SyncScoped {
  DisciplineFormula({
    required this.id,
    required this.disciplineProfileId,
    required String formulaKey,
    this.description,
    required String formulaText,
    required this.formulaType,
    required Map<String, Object?> inputs,
    Map<String, Object?>? outputs,
    List<String> dependsOn = const [],
    this.isPrimary = false,
    this.displayOrder = 0,
    required DateTime createdAt,
  }) : formulaKey = requireNotBlank(formulaKey, 'formulaKey'),
       formulaText = requireNotBlank(formulaText, 'formulaText'),
       inputs = Map.unmodifiable(inputs),
       outputs = outputs == null ? null : Map.unmodifiable(outputs),
       dependsOn = List.unmodifiable(dependsOn),
       createdAt = createdAt.toUtc() {
    if (dependsOn.contains(this.formulaKey)) {
      throw ArgumentError('a formula cannot depend on itself');
    }
  }

  factory DisciplineFormula.fromJson(Map<String, Object?> json) =>
      _$DisciplineFormulaFromJson(json);

  final Id id;
  final Id disciplineProfileId;

  /// Unique within the profile.
  final String formulaKey;

  final String? description;

  /// The expression, for example `flightPoints + landingBonus`.
  final String formulaText;

  final FormulaType formulaType;

  /// Maps each input name to the field or constant that provides it.
  final Map<String, Object?> inputs;

  /// Maps each output name to the target that receives the result.
  final Map<String, Object?>? outputs;

  /// Formula keys that must be computed first; cycles are not allowed.
  final List<String> dependsOn;

  /// The primary scoring formula; exactly one per profile version.
  final bool isPrimary;

  final int displayOrder;
  final DateTime createdAt;

  @override
  SyncScope get syncScope => SyncScope.system;

  Map<String, Object?> toJson() => _$DisciplineFormulaToJson(this);

  @override
  List<Object?> get props => [
    id,
    disciplineProfileId,
    formulaKey,
    description,
    formulaText,
    formulaType,
    inputs,
    outputs,
    dependsOn,
    isPrimary,
    displayOrder,
    createdAt,
  ];
}
