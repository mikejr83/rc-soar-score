import 'package:equatable/equatable.dart';

/// One problem found while validating a component set.
class ScoringIssue extends Equatable {
  const ScoringIssue({required this.code, required this.message, this.fieldId});

  /// Machine-readable code, for example `required` or `out_of_range`.
  final String code;
  final String message;

  /// The offending field, or null for a rule spanning several fields.
  final String? fieldId;

  @override
  List<Object?> get props => [code, message, fieldId];
}
