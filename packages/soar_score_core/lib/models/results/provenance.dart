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
