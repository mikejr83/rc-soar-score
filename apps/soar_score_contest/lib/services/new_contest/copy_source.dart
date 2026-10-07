import 'package:soar_score_core/soar_score_core.dart';

import 'wizard_discipline.dart';

/// A pilot of the source contest that can be copied (participation and
/// class only; only pilots are copied).
class SourcePilot {
  const SourcePilot({
    required this.profileId,
    required this.name,
    this.email,
    this.classification,
  });

  final Id profileId;
  final String name;
  final String? email;
  final String? classification;
}

/// The contest a new contest copies from, once its configuration and pilots
/// have loaded.
class CopySource {
  const CopySource({
    required this.contest,
    this.discipline,
    this.options,
    this.pilots = const [],
  });

  final Contest contest;

  /// The source's discipline, when it has a configuration with a supported
  /// one.
  final WizardDiscipline? discipline;

  /// The source's core options, when it has a configuration.
  final CoreOptions? options;

  final List<SourcePilot> pilots;
}
