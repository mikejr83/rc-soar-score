import 'package:equatable/equatable.dart';

import '../id.dart';

/// Whether a derived result's version stamps differ from the current ones.
///
/// A stale result must be recomputed before it is shown as official.
bool isStaleResult({
  required Id configRevisionId,
  required Id matrixRevisionId,
  required String calculationVersion,
  required Id currentConfigRevisionId,
  required Id currentMatrixRevisionId,
  required String currentCalculationVersion,
}) =>
    configRevisionId != currentConfigRevisionId ||
    matrixRevisionId != currentMatrixRevisionId ||
    calculationVersion != currentCalculationVersion;

/// The versions a derived result was computed under.
class ResultStamps extends Equatable {
  const ResultStamps({
    required this.configRevisionId,
    required this.matrixRevisionId,
    required this.calculationVersion,
  });

  final Id configRevisionId;
  final Id matrixRevisionId;
  final String calculationVersion;

  /// Whether these stamps differ from [current], so the result must be
  /// recomputed before it is shown as official.
  bool isStale(ResultStamps current) => isStaleResult(
    configRevisionId: configRevisionId,
    matrixRevisionId: matrixRevisionId,
    calculationVersion: calculationVersion,
    currentConfigRevisionId: current.configRevisionId,
    currentMatrixRevisionId: current.matrixRevisionId,
    currentCalculationVersion: current.calculationVersion,
  );

  @override
  List<Object?> get props => [
    configRevisionId,
    matrixRevisionId,
    calculationVersion,
  ];
}
