import 'package:soar_score_core/soar_score_core.dart';

import '../new_contest/wizard_discipline.dart';

/// How a discipline is named on the page: the same name the New Contest
/// wizard shows on its discipline card and in its summary.
abstract final class DisciplineLabel {
  /// `F5J`; the profile's own name for a profile the wizard has no card for.
  static String of(DisciplineProfile profile) =>
      WizardDiscipline.forProfile(profile.id)?.name ?? profile.name;

  /// The wizard's one-sentence description of the discipline's task, or
  /// `null` for a profile the wizard has no card for.
  static String? taskOf(DisciplineProfile profile) =>
      WizardDiscipline.forProfile(profile.id)?.task;

  /// `F5J default`.
  static String defaultOf(DisciplineProfile profile) =>
      '${of(profile)} default';
}
