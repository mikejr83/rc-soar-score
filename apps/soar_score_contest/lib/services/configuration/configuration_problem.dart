import 'package:soar_score_core/soar_score_core.dart';

/// What is wrong with a contest's saved configuration, in one sentence.
///
/// The matrix page and the workspace pass this to `DrawReadiness.evaluate`,
/// so there is one rule for it.
abstract final class ConfigurationProblem {
  /// `null` when the configuration is usable. [options] is the parsed
  /// [CoreOptions], or `null` when they are missing or invalid.
  static String? of({
    required ContestConfigurationRevision? configuration,
    required CoreOptions? options,
  }) {
    if (configuration == null) {
      return 'No configuration is saved yet, so the matrix can’t be drawn.';
    }
    if (options == null) {
      return 'The saved configuration is not valid, so the matrix can’t be '
          'drawn.';
    }
    return null;
  }
}
